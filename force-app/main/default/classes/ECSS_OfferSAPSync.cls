public class ECSS_OfferSAPSync {
@InvocableMethod(label='Flip SAP Sync Flag on Quote')
    public static void flipFlag(List<Id> quoteIds) {
        List<Quote> toUpdate = new List<Quote>();

        for (Id qId : quoteIds) {
            toUpdate.add(new Quote(
                Id = qId,
                ECSS_SAPSync__c = true
            ));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        System.enqueueJob(new ResetFlagJob(quoteIds));
    }

    public class ResetFlagJob implements Queueable {
        List<Id> quoteIds;
        public ResetFlagJob(List<Id> qIds) {
            this.quoteIds = qIds;
        }

        public void execute(QueueableContext qc) {
            List<Quote> toUpdate = new List<Quote>();
            for (Id qId : quoteIds) {
                toUpdate.add(new Quote(
                    Id = qId,
                    ECSS_SAPSync__c = false
                ));
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
    }
}