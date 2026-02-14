/*
    Name : UpdateReceiptAllocation
    Desc: This class is to update allocation.
    Date : 16-April-2025
*/
public class UpdateReceiptAllocationQueueable implements Queueable  {

    private List<ReceiptAllocation__c> receiptAllocationList;
    public UpdateReceiptAllocationQueueable( List<ReceiptAllocation__c> receiptAllocationList) {
        this.receiptAllocationList = receiptAllocationList;
    }

    public void execute(QueueableContext context) {
        if(receiptAllocationList != null && receiptAllocationList.size() > 0 ){
            update receiptAllocationList;
        }
    }
}