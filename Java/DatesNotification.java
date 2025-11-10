import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

private static final int FIRST_NOTIFICATION_DAYS = 15;
private static final int SECOND_NOTIFICATION_DAYS = 15;

public class NotificationScheduler {

    public static void main(String[] args) {
        // Assume this is the start date (could come from DB or API)
        LocalDateTime startDate = LocalDateTime.of(2025, 8, 1, 10, 0);  // August 1, 2025 at 10:00 AM

        // Call the logic that checks and triggers notifications
        checkAndSendNotifications(startDate);
    }

    public static void checkAndSendNotifications(LocalDateTime startDate) {

        private static boolean firstNotificationSent = false;
        private static boolean secondNotificationSent = false;
        LocalDateTime now = LocalDateTime.now();

        LocalDateTime firstNotificationDate = startDate.plusDays(FIRST_NOTIFICATION_DAYS);
        LocalDateTime secondNotificationDate = firstNotificationDate.plusDays(SECOND_NOTIFICATION_DAYS);

      if (now.isAfter(firstNotificationDate) && now.isBefore(secondNotificationDate) && !firstNotificationSent) {
    System.out.println("✅ Time to send FIRST notification.");
    firstNotificationSent = true;
}

if (now.isAfter(secondNotificationDate) && !secondNotificationSent) {
    System.out.println("✅ Time to send SECOND notification.");
    secondNotificationSent = true;
}

        // Debug print (optional)
        System.out.println("Now: " + now);
        System.out.println("First Notification Date: " + firstNotificationDate);
        System.out.println("Second Notification Date: " + secondNotificationDate);
    }
}
