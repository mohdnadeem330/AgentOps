public with sharing class DigitalSPAQueueable implements Queueable, Database.AllowsCallouts {
    public Set<Id> accountIds; // Parameter to hold Account IDs
    public String Category;
    // Constructor to accept the parameters
    public DigitalSPAQueueable(Set<Id> accIds,String Category) {
        this.accountIds = accIds;
        this.Category = Category;
    }
    public void execute(QueueableContext context) {
        // Start the batch job from inside the Queueable
        SendWhatsAppLinkWithBitly myBatchJob = new SendWhatsAppLinkWithBitly(accountIds,Category);
        Database.executeBatch(myBatchJob, 1); // Adjust batch size as needed
    }
}