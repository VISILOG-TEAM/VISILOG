package db.migration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

// Organizations move from a single wifi_network_name column to a real
// one-to-many wifi_networks table, same restructuring V21 did for
// office locations (and for the same reason: a Java migration so the
// backfilled row's id can be generated with java.util.UUID instead of a
// Postgres-only function like gen_random_uuid()).
public class V28__WifiNetworks extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();

        try (Statement st = conn.createStatement()) {
            st.execute(
                    "CREATE TABLE wifi_networks ("
                            + "id               UUID PRIMARY KEY,"
                            + "organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,"
                            + "name             VARCHAR(255) NOT NULL,"
                            + "created_at       TIMESTAMP NOT NULL"
                            + ")");
        }

        try (PreparedStatement select = conn.prepareStatement(
                "SELECT id, wifi_network_name FROM organizations "
                        + "WHERE wifi_network_name IS NOT NULL AND trim(wifi_network_name) <> ''");
                ResultSet rs = select.executeQuery()) {
            try (PreparedStatement insert = conn.prepareStatement(
                    "INSERT INTO wifi_networks (id, organization_id, name, created_at) "
                            + "VALUES (?, ?, ?, ?)")) {
                boolean any = false;
                while (rs.next()) {
                    insert.setObject(1, UUID.randomUUID());
                    insert.setObject(2, rs.getObject("id", UUID.class));
                    insert.setString(3, rs.getString("wifi_network_name"));
                    insert.setTimestamp(4, Timestamp.from(Instant.now()));
                    insert.addBatch();
                    any = true;
                }
                if (any) {
                    insert.executeBatch();
                }
            }
        }

        try (Statement st = conn.createStatement()) {
            st.execute("ALTER TABLE organizations DROP COLUMN wifi_network_name");
        }
    }
}
