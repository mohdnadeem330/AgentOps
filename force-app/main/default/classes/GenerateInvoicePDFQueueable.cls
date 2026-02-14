/**
* @File Name : GenerateInvoicePDFQueueable.cls
* @Description :
* @Author :
* @Last Modified By : Pooja @aldar.com
* @Last Modified On : October 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 13, 2025 |   | Initial Version
**/

public class GenerateInvoicePDFQueueable implements Queueable {
    private List<Id> paymentIds;

    public GenerateInvoicePDFQueueable(List<Id> paymentIds) {
        this.paymentIds = paymentIds;
    }

    public void execute(QueueableContext context) {
        if (paymentIds != null && !paymentIds.isEmpty()) {
            DmCaseInvoiceDoc.generatePDF(paymentIds);
            DM_SendPaymentInvoice.sendInvoicepdfHelper(paymentIds[0], 'xyz');
            //System.enqueueJob(new sendInvoicePDF(paymentIds[0], 'xyz'));
        }
    }
}