public class ExchangeRateApiQueueable implements Queueable {
    public ExchangeRateApiQueueable() {

    }

    public void execute(QueueableContext context) { 
        ExchangeRateApiClass.fetchLatestExchangeRate();
    }
}