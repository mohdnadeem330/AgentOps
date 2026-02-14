/*
* Class Name : DLPZoneController
* Created By : R3-DLP implementation-Smaartt
* Description:Class DLPZoneController unit search under Account
* 
*/
public without sharing class DLPZoneController {
    
    @AuraEnabled(cacheable=true)
    public static List<DLPWrapper> dlpZoneRetrieve(String accid) {        
        List<DLPWrapper> result  = new List<DLPWrapper>();
        try{
            if(accid!= null && accid != ''){
                List<Id> unitIds = new List<id>();
                for(SalesOrder__c wraperObj : [SELECT Id, Name, Account__c, Unit__c, Unit__r.DLPZone__c,Unit__r.Name,CustomerDLPStartDate__c,DLPDate__c,PMAStatus__c,
                                               Unit__r.DLPZone__r.ContractorDLPStartDate__c, Unit__r.DLPZone__r.ContractorDLPEndDate__c, CustomerDLPStatus__c,
                                               Unit__r.DLPZone__r.ContractorDLPStatus__c,Status__c,ProjectName__c, AMCEndDate__c, AMCStartDate__c,AMCStatus__c,TotalOutstanding__c,HandoverRFOPayDueDate__c,
                                               HoldReasonCode__c,HoldFlag__c,(SELECT Id,SalesOrder__c,SalesOrder__r.Unit__c,BalanceQuantity__c,Product_Item__c,Product_Item__r.Product2Id,Product_Item__r.Product2.Name,Product_Item__r.Product2.Description,QuantityOnHand__c,ConsumedQuantity__c,QuantityInProgress__c,Product_Item__r.Product2.QuantityUnitOfMeasure FROM OpportunityOfferLines__r WHERE  Product_Item__r.Product2.Type__c = 'On Demand' AND Product_Item__r.Product2.isActive = True)
                                               FROM SalesOrder__c WHERE Account__c = :accid]){                                                
                                                   unitIds.add(wraperObj.Unit__c);
                                                   DLPWrapper newRec = new DLPWrapper();     
                                                   newRec.account = wraperObj.Account__c ; 
                                                   newRec.unit = wraperObj.Unit__c ; 
                                                   newRec.soId = wraperObj.Id ; 
                                                   newRec.unitName = wraperObj.Unit__r.Name;
                                                   newRec.dlpEndDate = string.valueOf(wraperObj.DLPDate__c); 
                                                   newRec.dlpStartDate =   string.valueOf(wraperObj.CustomerDLPStartDate__c) ; 
                                                   newRec.status = wraperObj.CustomerDLPStatus__c == 'Active'? True:false ;
                                                   newRec.isDisableDLP =  wraperObj.CustomerDLPStatus__c.equalsIgnoreCase('Active') || wraperObj.AMCStatus__c.equalsIgnoreCase('Active') || wraperObj.PMAStatus__c.equalsIgnoreCase('Active') || ( wraperObj.Unit__r.DLPZone__c != null && wraperObj.Unit__r.DLPZone__r.ContractorDLPStatus__c.equalsIgnoreCase('Active')) ? false : true ;
                                                   newRec.dlpZoneName = wraperObj.Name; 
                                                   newRec.SoStatus = wraperObj.Status__c ;
                                                   newRec.ProjectName = wraperObj.ProjectName__c;
                                                   newRec.TotalOutstanding = string.valueOf(wraperObj.TotalOutstanding__c);
                                                   newRec.AMCEndDate = string.valueOf(wraperObj.AMCEndDate__c);
                                                   newRec.AMCStartDate = string.valueOf(wraperObj.AMCStartDate__c);
                                                   newRec.AMCStatus = wraperObj.AMCStatus__c;
                                                   newRec.isAMCActive = (wraperObj.AMCStatus__c != null && wraperObj.AMCStatus__c == 'Active' ? true : false); 
                                                   newRec.HandoverRFODate = string.valueOf(wraperObj.HandoverRFOPayDueDate__c);
                                                   newRec.HoldFlag = wraperObj.HoldFlag__c;
                                                   newRec.HoldReason = wraperObj.HoldReasonCode__c;
                                                   newRec.lstOfferLines = wraperObj.OpportunityOfferLines__r;
                                                   /*Added by Cloudzlab no longer using this
                                                   newRec.ECSSUnitId = wraperObj.Unit__r.ECSS_Unit__c;
                                                   newRec.ECSSUnitName = wraperObj.Unit__r.ECSS_Unit__r.Name;
                                                   End*/
                                                   result.add(newRec); 
                                               } 
                Map<id,Unit__c> mapUnitRec = new  Map<id,Unit__c>([Select id,DLPZone__c,Name,UnitType__c,
                                                                   DLPZone__r.ContractorDLPStartDate__c, DLPZone__r.ContractorDLPEndDate__c, 
                                                                   DLPZone__r.ContractorDLPStatus__c,(select id,AccountId,Assigned_To__c,Assigned_To__r.Name, OwnerId,Owner.Name,CaseCategory__c,SubCategory__c,SubVertical__c,CaseNumber,Account.Name,Subject,CreatedDate,Assigned_Service_Executive__c,Assigned_Service_Executive__r.Name,Status from Cases__r where status != 'Closed' and Recordtype_Name__c !='Corporate_Legal') from Unit__c where id in:unitIds]) ;
                
                
                
                for (DLPWrapper wraperResult : result ){
                    Unit__c unitRec =  mapUnitRec.get(wraperResult.unit);
                    wraperResult.unitName = unitRec.Name;                
                    wraperResult.caseCount = unitRec.Cases__r.size() ;                 
                    wraperResult.caseRelatedToUnit = unitRec.Cases__r ;
                    wraperResult.UnitType = unitRec.UnitType__c;
                } } }catch(exception e){  return result;  }
        return result;
        
    } 
    @AuraEnabled(cacheable=true)
    Public static List<Case> getCasesForAccount(Id accountId){
        return [SELECT Id, CaseNumber, CaseCategory__c,Unit__c,Unit__r.Name,SalesOrder__c,SalesOrder__r.Name, CreatedDate, Status,Recordtype_Name__c FROM Case WHERE AccountId = :accountId and status != 'Closed' ORDER BY CreatedDate DESC];
    }
    
    @AuraEnabled
    public static boolean CheckJointRelationAccount(Id accountId) {
        try {            
            List<jointowner__C> jointOwnerAccount = [Select Id,Account__c, RelationshipType__c  From jointowner__C where RelationshipType__c ='Joint owner p-p'  and Account__c =:accountId];
            return (!jointOwnerAccount.Isempty());
        } catch (Exception e) {
            System.debug('Error in checkDuplicate: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while checking for duplicates: ' + e.getMessage());
        }
    }
    
    
    
    public class DLPWrapper {
        @AuraEnabled 
        public string account ; 
        @AuraEnabled 
        public string dlpZoneName ; 
        @AuraEnabled 
        public string unit ; 
        @AuraEnabled 
        public string unitName ; 
        @AuraEnabled 
        public string soId ; 
        @AuraEnabled 
        public string dlpEndDate ; 
        @AuraEnabled 
        public string dlpStartDate ; 
        @AuraEnabled 
        public Boolean status ; 
        @AuraEnabled 
        public string SoStatus ; 
        @AuraEnabled 
        public Integer caseCount ;
        @AuraEnabled 
        public List<Case> caseRelatedToUnit ;
        @AuraEnabled 
        public List<OpportunityOfferLine__c> lstOfferLines ;
        @AuraEnabled 
        public string ProjectName;
        @AuraEnabled 
        public string TotalOutstanding;
        @AuraEnabled 
        public string AMCEndDate;
        @AuraEnabled 
        public string AMCStartDate;
        @AuraEnabled 
        public string AMCStatus;
        @AuraEnabled 
        public boolean isAMCActive;
        @AuraEnabled 
        public string HandoverRFODate;
        @AuraEnabled 
        public Boolean HoldFlag;
        @AuraEnabled 
        public string HoldReason;
        @AuraEnabled 
        public string UnitType;
        @AuraEnabled 
        public Boolean isDisableDLP;
        /*Added by Cloudzlab no longer using this
        @AuraEnabled
        public string ECSSUnitId;
        @AuraEnabled
        public string ECSSUnitName;
         */
    } 
    /*
    @AuraEnabled(cacheable=true)
    public static List<Case> getPrviousDLPCases(Id caseId, Integer days) {
        
        Case cs = New Case();
        
        If(!String.isBlank(caseId))
        {
            cs = [Select Id, CaseNumber, Skills_Required__c, ProblemCode__c, Unit__c From Case Where Id = :caseId];
        }
        
        String querystr = 'SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Skills_Required__c, ProblemCode__c, Unit__c, Unit__r.Name, Owner.Name ' + 
            'From Case Where Skills_Required__c = : cs.Skills_Required__c AND ProblemCode__c = : cs.ProblemCode__c AND Unit__c = :cs.Unit__c  ' +
            'AND Id != :caseId AND CreatedDate = LAST_N_DAYS:' + days + 'ORDER BY CreatedDate DESC ';
        
        List<Case> caselist = Database.query(querystr);
        return caselist;
        
        /* return [
/* SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Skills_Required__c, ProblemCode__c, Unit__c, Unit__r.Name, Owner.Name 
FROM Case 
WHERE Skills_Required__c = :cs.Skills_Required__c
AND ProblemCode__c = : cs.ProblemCode__c
AND Unit__c = :cs.Unit__c
AND Id != :caseId
AND CreatedDate = LAST_N_DAYS:days 
ORDER BY CreatedDate DESC  

];*/
   // }
    /* Commented By Narayana Start
    @AuraEnabled(cacheable=true)
    public static List<DLPCase_Settings__mdt> getnoofDays() {
        return [
            SELECT Days__c
            From DLPCase_Settings__mdt
            Where Type__c = 'Days'
            Order by Days__c
        ];
    }
    */ // Commented By Narayana END
    
}