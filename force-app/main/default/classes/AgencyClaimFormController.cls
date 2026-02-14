public with sharing class AgencyClaimFormController {
    
    

    public static String comlineitem		{set;get;}
    public static List<CommDetails> displayCommList  {get;set;}
    public static List<ApprovalHistoryDetails> displayApprovalList  {get;set;}

    /*
* Get Installment & Sales Order Details by record Id
*/
    commissionLineItem__c comm;
    public AgencyClaimFormController(ApexPages.StandardController stdController) {
        comm = (commissionlineitem__c)stdController.getRecord();
    

 //   @AuraEnabled(cacheable=true)
    //public static void getApprovalHistoryDetailsn(){
        try {
            
            Id commlineitemid = ApexPages.currentPage().getParameters().get('id'); 
            
            System.debug('**Commission Line Item**'+commlineitemid);
            displayCommList = new List<CommDetails>();
            displayApprovalList = new List<ApprovalHistoryDetails>();
            //------ Query Sales Order and related records
            //Map<String,CommDetails> commlist = new Map<String,CommDetails>();
            List<CommDetails> comitems = new List<CommDetails>();
            List<commissionlineitem__c> comitem1 = new List<commissionlineitem__c>();
            comitem1 = [SELECT id, name, CommissionAmount__c, SalesOrder__r.ProjectName__c, SalesOrder__r.Unit__r.CommunityName__c, SalesOrder__r.UnitNumber__c, SalesOrder__r.name, SalesOrder__r.NetAmount__c,SalesOrder__r.BookingDate__c,BrokerAgency__r.name, InvoiceDate__c, InvoiceNumber__c, InvoiceReferenceNumber__c   from commissionlineitem__c where id =:commlineitemid];
            List<ProcessInstanceStep> approvalList1 = new List<ProcessInstanceStep>();
            approvalList1 = [SELECT id,Actor.name,ActorId, StepStatus,CreatedBy.name,CreatedDate, OriginalActor.name,Actor.UserRole.Name, Actor.Username from ProcessInstanceStep where processinstance.TargetObjectId =:commlineitemid and StepStatus='Approved' order by createddate desc];
            
            
            
            List<ApprovalHistoryDetails> tempapprovals = new List<ApprovalHistoryDetails>();
                for(ProcessInstanceStep ap:approvalList1){
                    ApprovalHistoryDetails tempapproval = new ApprovalHistoryDetails();
                    tempapproval.approvedby = ap.Actor.name;
                    tempapproval.title = ap.Actor.UserRole.Name;
                    tempapproval.approveddt = ap.CreatedDate.Date();
                    tempapproval.username = ap.Actor.Username;
                    tempapprovals.add(tempapproval);
                }
            

                for(commissionlineitem__c comitem: comitem1 ){

                    CommDetails tempcom = new CommDetails();
                    tempcom.projectname = comitem.SalesOrder__r.ProjectName__c;
                    tempcom.community = comitem.SalesOrder__r.Unit__r.CommunityName__c;
                    tempcom.unitnumber = comitem.SalesOrder__r.UnitNumber__c;
                    tempcom.salesordernumber = comitem.SalesOrder__r.name;
                    tempcom.salesorderdate = comitem.SalesOrder__r.BookingDate__c;
                    tempcom.salesorderamt = comitem.SalesOrder__r.NetAmount__c;
                    tempcom.commamt = comitem.CommissionAmount__c;
                    tempcom.brokeragency = comitem.BrokerAgency__r.name;
                    tempcom.invoicenum = comitem.InvoiceReferenceNumber__c;
                    tempcom.invoicedt = comitem.InvoiceDate__c;
                    comlineitem = comitem.name;
                    comitems.add(tempcom);
                }

            displayCommList = comitems;
            displayApprovalList = tempapprovals;
            system.debug('displayList '+displayCommList);
            String fileName = 'Agency Claim Form for Commission: '+comlineitem;
            //+salesOrderDetail.Name;
            Apexpages.currentPage().getHeaders().put('content-disposition', 'filename='+fileName+'.pdf');
        } catch (Exception e) {
            throw e;
        }
    }
    
    public class CommDetails{
        public String projectname        {set;get;}
        public String community      {set;get;}
        public String unitnumber      {set;get;}
        public String salesordernumber      {set;get;}
        public Date salesorderdate      {set;get;}
        public Decimal salesorderamt      {set;get;}
        public Decimal commamt      {set;get;}
        public String brokeragency  {set;get;}
        public String invoicenum  {set;get;}
        public Date invoicedt  {set;get;}
        //public List<ApprovalHistoryDetails> approvalhistorydet  {set;get;}
    }
    
    public class ApprovalHistoryDetails{
        //public Decimal srno  {set;get;}
        public String approvedby  {set;get;}
        public String title      {set;get;}
       	public String username  {set;get;}
        public Date approveddt  {set;get;}
    }
}