import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
import pytz

logger = logging.getLogger(__name__)
scheduler = BackgroundScheduler()


def overdue_payment_job():
    """Weekly job to send overdue payment summary notifications."""
    from services.notification_service import send_overdue_payment_summary
    logger.info("Running weekly overdue payment check...")
    result = send_overdue_payment_summary()
    logger.info(f"Overdue check result: {result}")


def start_scheduler():
    """Start the APScheduler with the weekly overdue payment job."""
    try:
        pkt = pytz.timezone("Asia/Karachi")

        # Every Monday at 9:00 AM PKT
        scheduler.add_job(
            overdue_payment_job,
            CronTrigger(day_of_week="mon", hour=9, minute=0, timezone=pkt),
            id="weekly_overdue_check",
            replace_existing=True,
        )

        scheduler.start()
        logger.info("Scheduler started: weekly overdue check scheduled for Monday 9:00 AM PKT")
    except Exception as e:
        logger.error(f"Failed to start scheduler: {e}")


def stop_scheduler():
    """Shutdown the scheduler gracefully."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Scheduler stopped")
