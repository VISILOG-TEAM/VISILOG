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

// Organizations move from a single office_latitude/longitude/radius to
// a real one-to-many office_locations table (see OfficeLocation entity,
// gated to more than one location per org via
// PlanFeatureService/OfficeLocationService). A Java migration rather
// than plain SQL purely so the backfilled rows' ids can be generated
// with java.util.UUID instead of a Postgres-only function like
// gen_random_uuid(), which the H2-in-Postgres-mode test database (see
// application-test.yml) isn't guaranteed to support.
public class V21__MultipleOfficeLocations extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();

        try (Statement st = conn.createStatement()) {
            st.execute(
                    "CREATE TABLE office_locations ("
                            + "id               UUID PRIMARY KEY,"
                            + "organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,"
                            + "name             VARCHAR(255) NOT NULL,"
                            + "latitude         DOUBLE PRECISION NOT NULL,"
                            + "longitude        DOUBLE PRECISION NOT NULL,"
                            + "radius_meters    INTEGER NOT NULL,"
                            + "created_at       TIMESTAMP NOT NULL"
                            + ")");
        }

        try (PreparedStatement select = conn.prepareStatement(
                "SELECT id, office_latitude, office_longitude, office_radius_meters "
                        + "FROM organizations WHERE office_latitude IS NOT NULL");
                ResultSet rs = select.executeQuery()) {
            try (PreparedStatement insert = conn.prepareStatement(
                    "INSERT INTO office_locations "
                            + "(id, organization_id, name, latitude, longitude, radius_meters, created_at) "
                            + "VALUES (?, ?, 'Main office', ?, ?, ?, ?)")) {
                boolean any = false;
                while (rs.next()) {
                    insert.setObject(1, UUID.randomUUID());
                    insert.setObject(2, rs.getObject("id", UUID.class));
                    insert.setDouble(3, rs.getDouble("office_latitude"));
                    insert.setDouble(4, rs.getDouble("office_longitude"));
                    insert.setInt(5, rs.getInt("office_radius_meters"));
                    insert.setTimestamp(6, Timestamp.from(Instant.now()));
                    insert.addBatch();
                    any = true;
                }
                if (any) {
                    insert.executeBatch();
                }
            }
        }

        try (Statement st = conn.createStatement()) {
            st.execute("ALTER TABLE organizations DROP COLUMN office_latitude");
            st.execute("ALTER TABLE organizations DROP COLUMN office_longitude");
            st.execute("ALTER TABLE organizations DROP COLUMN office_radius_meters");
        }
    }
}
