public class PaymentMilestoneScreenFlow {
    @InvocableMethod(label='Process Account IDs and Return Messages' description='Process Account IDs and return custom messages to Flow')
    public static List<OutputMessage> processAccountIds(List<InputPaymentInstallment> paymentInstallments) {
        List<OutputMessage> outputMessages = new List<OutputMessage>();
        String Payment_Installment_Ids = string.valueof(paymentInstallments[0].paymentInstallmentIds);
        set<Id> paymentIdCount =new Set<Id>();
        string message='Success';
        List<PaymentInstallments__c> approvalPendingList=[select Id From PaymentInstallments__c where Id In :paymentInstallments[0].paymentInstallmentIds and ApprovalStatus__c In ('Approval Pending','Approved')];
        
        for(InstallmentLines__c IL :[select Id,PaymentInstallments__c, PaymentInstallments__r.Name  from InstallmentLines__c where PaymentInstallments__c In :paymentInstallments[0].paymentInstallmentIds])
        {
            paymentIdCount.add(IL.PaymentInstallments__c);
        }
        
        if(paymentIdCount.size()!=paymentInstallments[0].paymentInstallmentIds.size())
        {
            message = 'Installment Lines Not available';
            outputMessages.add(new OutputMessage(message));
            return outputMessages; 
        }
        if(approvalPendingList.size() > 0){ message = 'Approval Pending';outputMessages.add(new OutputMessage(message));return outputMessages;}
        
        date InstallmentDate = null;
        String PaymentPlan =null;
        String Project=null;
        List<PaymentInstallments__c> paymentInstallmentList=[select Id,InstallmentDate__c,Associated_Projects__c,PaymentPlan__c  From PaymentInstallments__c where Id In :paymentInstallments[0].paymentInstallmentIds];
        
        for(integer i=0;i<paymentInstallmentList.size();i++)
        {
            if(paymentInstallmentList[i].InstallmentDate__c !=null || paymentInstallmentList[i].PaymentPlan__c !=null )
            {                
                if(i==0)
                {
                    
                    InstallmentDate = paymentInstallmentList[i].InstallmentDate__c;                   
                    PaymentPlan = paymentInstallmentList[i].PaymentPlan__c;
                   // Project = paymentInstallmentList[i].Associated_Projects__c;
                }
                
                
                
                if(paymentInstallmentList[i].InstallmentDate__c != InstallmentDate || paymentInstallmentList[i].PaymentPlan__c != PaymentPlan )//|| paymentInstallmentList[i].Associated_Projects__c != Project
                {
                    
                    message = 'Select Data difference';
                    outputMessages.add(new OutputMessage(message));
                    return outputMessages;
                    
                }
            }
            else
            {
                message = 'Date Not Avilable';
                outputMessages.add(new OutputMessage(message));
                return outputMessages;            
            }
            
        
        }
        
        outputMessages.add(new OutputMessage(message)); return outputMessages;  
        
    }
    
    // Input class: Used to pass Account IDs from Flow to Apex
    public class InputPaymentInstallment {
        @InvocableVariable(label='Payment Installment IDs' description='Payment Installment IDs for processing')
        public List<Id> paymentInstallmentIds;
    }
    
    // Output class: Used to return messages back to Flow
    public class OutputMessage {
        @InvocableVariable(label='Message' description='Message to be returned to Flow')
        public String message;
        
        public OutputMessage(String message) {
            this.message = message;
        }
    }
}