import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class DbFix {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres?sslmode=require";
        String user = "postgres.pqqpzsqkcgprucarqpcl";
        String password = "QNQIcLQSS4pg9qkY";

        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            System.out.println("Connected to database. Adding columns...");
            
            try {
                stmt.execute("ALTER TABLE difficulty_progress ADD COLUMN sentence_completion_cleared BOOLEAN NOT NULL DEFAULT FALSE;");
                System.out.println("Added sentence_completion_cleared.");
            } catch (Exception e) {
                System.out.println("Could not add sentence_completion_cleared: " + e.getMessage());
            }

            try {
                stmt.execute("ALTER TABLE difficulty_progress ADD COLUMN sentence_rearrangement_cleared BOOLEAN NOT NULL DEFAULT FALSE;");
                System.out.println("Added sentence_rearrangement_cleared.");
            } catch (Exception e) {
                System.out.println("Could not add sentence_rearrangement_cleared: " + e.getMessage());
            }
            
            System.out.println("Done.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
