global with sharing class MemoEmailController {

    global String memoId{get;set;}

    global MemoEmailController() {
    }

    global String memoProject{
        get{        
            String memoProjectId;
            
            MemoLines__c memoLinesObject = [SELECT Unit__r.Project__r.Id FROM MemoLines__c WHERE BookingMemo__c =:memoId Limit 1];
            
            memoProjectId = memoLinesObject.Unit__r.Project__r.Id;
            
            return  memoProjectId;
        }
        set;
    }

    global String projectBudgetId{
        get{        
            String projectBudget;
            
            MemoLines__c memoLinesObject = [SELECT Unit__r.ProjectBudget__c FROM MemoLines__c WHERE BookingMemo__c =:memoId Limit 1];
            
            projectBudget = memoLinesObject.Unit__r.ProjectBudget__c;
            
            return  projectBudget;
        }
        set;
    }

    global Integer unitCount{
        get{   
            Integer unitCounter = 0;   
            if (memoProject != null) {
                for(Unit__c unitObject:[Select Id from Unit__c where Project__c =:memoProject AND Status__c =: Constants.UNIT_STATUS_AVAILABLE]){
                    unitCounter++;
                }
            }  
            return  unitCounter;
        }
        set;
    }

    global BookingMemo__c memoReqList{
        get{        
            BookingMemo__c bookingMemoObject = [SELECT MemoSubject__c,MemoType__c,MemoHeader__c,RelatedOpportunity__r.Name,RelatedOpportunity__c,SpecialNote__c,RelatedOpportunity__r.SaleType__c FROM BookingMemo__c WHERE Id =:memoId Limit 1];
            
            return  bookingMemoObject;
        }
        set;
    }

    global Boolean IntCommissionPercentageFlag{get;set;}
    global Boolean AttachmentFlag{get;set;}
    global Boolean ADMFeePercentageFlag{get;set;}
    global Boolean SCWaiverYearsFlag{get;set;}
    global Boolean BrokerCommissionPercentageFlag{get;set;}
    global Boolean HomeMaintenanceYearsFlag{get;set;}
    global Boolean PMFeeYearsFlag{get;set;}
    global Boolean RebatePercentageFlag{get;set;}

    global List<MemoLines__c> memoLinesReqList{
        get{        
            List<MemoLines__c> memoLinesToDisplay = new List<MemoLines__c>();
            for(MemoLines__c memoLinesObject:[SELECT Unit__r.Name, Unit__r.MeasuredArea__c, Unit__r.UnitType__c, Unit__r.SellingPrice__c, DiscountPercentage__c, PriceAfterDiscount__c,IntCommissionPercentage__c,ADMFeePercentage__c, NetImpact__c,SCWaiverYears__c,BrokerCommissionPercentage__c,HomeMaintenanceYears__c, PMFeeYears__c, RebatePercentage__c FROM MemoLines__c WHERE BookingMemo__c =:memoId]){
                memoLinesToDisplay.add(memoLinesObject);
                if (memoLinesObject.IntCommissionPercentage__c != null) {
                    IntCommissionPercentageFlag = true;
                }
                if (memoLinesObject.ADMFeePercentage__c != null) {
                    ADMFeePercentageFlag = true;
                }
                if (memoLinesObject.SCWaiverYears__c != null) {
                    SCWaiverYearsFlag= true;
                }
                if (memoLinesObject.BrokerCommissionPercentage__c != null) {
                    BrokerCommissionPercentageFlag= true;
                }
                if (memoLinesObject.HomeMaintenanceYears__c != null) {
                    HomeMaintenanceYearsFlag= true;
                }
                if (memoLinesObject.PMFeeYears__c != null) {
                    PMFeeYearsFlag= true;
                }
                if (memoLinesObject.RebatePercentage__c != null) {
                    RebatePercentageFlag= true;
                }
            }
            
            return  memoLinesToDisplay;
        }
        set;
    }

    global netImpactWrapper netImpactReq{
        get{        
            netImpactWrapper netImpactToDisplay;
            Decimal totalUnitPriceSum = 0;
            Decimal totalOfferSum = 0;

            for(MemoLines__c memoLinesObject:[SELECT Unit__r.SellingPrice__c, NetValue__c  FROM MemoLines__c WHERE BookingMemo__c =:memoId]){
                totalUnitPriceSum = totalUnitPriceSum + memoLinesObject.Unit__r.SellingPrice__c;
                totalOfferSum = totalOfferSum + memoLinesObject.NetValue__c;
            }
            netImpactToDisplay = new netImpactWrapper(totalUnitPriceSum, totalOfferSum);
            
            return  netImpactToDisplay;
        }
        set;
    }

    global List<MemoLines__c> memoTrendList{
        get{        
    
            List<MemoLines__c> memoTrendToDisplay = new List<MemoLines__c>();
            if (memoProject != null) {
                for(MemoLines__c memoLinesObject:[SELECT Unit__r.Name, Unit__r.MeasuredArea__c, Unit__r.UnitType__c, Unit__r.SellingPrice__c, DiscountPercentage__c, PriceAfterDiscount__c,IntCommissionPercentage__c, NetImpact__c,SCWaiverYears__c,BrokerCommissionPercentage__c,SubsidyPercentage__c,HomeMaintenanceYears__c, PMFeeYears__c, RebatePercentage__c FROM MemoLines__c WHERE Unit__r.Project__c =:memoProject AND BookingMemo__r.ApprovalStatus__c = :Constants.STATUS_APPROVED limit 6]){
                    memoTrendToDisplay.add(memoLinesObject);
                }
            }
            return  memoTrendToDisplay;
        }
        set;
    }

    global List<MemoLines__c> saleTrendList{
        get{        
            List<Id> unitsIds = new List<Id>();
            if (memoProject != null) {
                for(SalesOrder__c salesOrderObject:[SELECT Unit__c FROM SalesOrder__c WHERE Unit__r.Project__c =:memoProject AND (Status__c =:'Pending' OR Status__c =:'Approve Pending' OR Status__c =:'Sold')]){
                    unitsIds.add(salesOrderObject.Unit__c);
                }
            }
    
            List<MemoLines__c> saleTrendToDisplay = new List<MemoLines__c>();
            for(MemoLines__c memoLinesObject:[SELECT Unit__r.Name, Unit__r.MeasuredArea__c, Unit__r.UnitType__c, Unit__r.SellingPrice__c, DiscountPercentage__c, PriceAfterDiscount__c,IntCommissionPercentage__c, NetImpact__c,SCWaiverYears__c,BrokerCommissionPercentage__c, RebatePercentage__c FROM MemoLines__c WHERE  Unit__c IN:unitsIds Limit 6]){
                saleTrendToDisplay.add(memoLinesObject);
            }
            
            return  saleTrendToDisplay;
        }
        set;
    }

    global List<ProjectBudget__c> budgetLineSummaryList{
        get{        
            List<ProjectBudget__c> budgetLineToDisplay = new List<ProjectBudget__c>();
            if (memoProject != null) {
                for(ProjectBudget__c budgetLineObject:[SELECT TotalSalesSupportBucket__c,TotalDiscountBucket__c,UtilizedSalesSupportBucket__c,UtilizedDiscountBucket__c,AvailableSalesSupportBucket__c,AvailableDiscountBucket__c,SummaryReport__c,SalesOrderReport__c FROM ProjectBudget__c WHERE id =:projectBudgetId ]){
                    budgetLineToDisplay.add(budgetLineObject);
                }
            }
            return  budgetLineToDisplay;
        }
        set;
    }

    global List<DataTableWrapper> approvalHistoryReqList{
        get{        
            Integer counter = 1;
            List<DataTableWrapper> approvalHistoryToDisplay = new List<DataTableWrapper>();
            //List<User> userData = new List<User>();
            BookingMemo__c memoRecord = [select id,ApprovalStatus__c from BookingMemo__c where id = :memoId limit 1 ];
            boolean isFirstStep = false;
            for(ProcessInstance processInstanceObject :[SELECT Id,createddate, (SELECT StepStatus, createddate, Actor.Name,ActorId FROM StepsAndWorkitems order by CreatedDate asc) FROM ProcessInstance where TargetObjectId =:memoId order by createdDate desc limit 1]){
                for(ProcessInstanceHistory processInstanceHistoryObject:processInstanceObject.StepsAndWorkitems){
                    //userData = [SELECT Id,Name FROM User WHERE Id =:processInstanceHistoryObject.ActorId];

                    approvalHistoryToDisplay.add(new DataTableWrapper(processInstanceHistoryObject.StepStatus, counter, processInstanceHistoryObject.Actor.Name , processInstanceHistoryObject.createddate.format('MMMMM dd, yyyy')));
                    counter = counter + 1;
                    isFirstStep = Math.abs( (processInstanceObject.StepsAndWorkitems[0].createddate.getTime() - system.Now().getTime())/60000 ) < 1;
                }            
                
            }
            integer totalValues= approvalHistoryToDisplay.size();

            List<DataTableWrapper> finalTableToReturn = new  List<DataTableWrapper>();
            for (Integer i = 0; i < approvalHistoryToDisplay.size(); i++) {
                if(i>= totalValues-2){
                    break;
                }
                finalTableToReturn.add(approvalHistoryToDisplay[i]);
            }
            //Correct Email //Last 2 line items are created together and thus we need to shuffle them
            if(approvalHistoryToDisplay.size()>1 && approvalHistoryToDisplay[(totalValues-2)].action.equalsIgnoreCase('Pending')){
                approvalHistoryToDisplay[(totalValues-2)].counter = totalValues;
                approvalHistoryToDisplay[(totalValues-1)].counter = totalValues-1;
                finalTableToReturn.add(approvalHistoryToDisplay[(totalValues-1)]);
                finalTableToReturn.add(approvalHistoryToDisplay[(totalValues-2)]);
            }
            //As email are sent before mark last item as approved
            if(approvalHistoryToDisplay.size()>1){
                finalTableToReturn[totalValues-1].action= (isFirstStep?'Pending':'Approved');
            }

            return  finalTableToReturn;
        }
        set;
    }
   
    public class netImpactWrapper {

        public Decimal totalUnitPrice { get; set; }
        public Decimal totalOffer { get; set;}
        public String totalImpact { get; set;}

        Decimal totalImpactValue;

        public netImpactWrapper(Decimal totalUnitPrice, Decimal totalOffer) {
          this.totalUnitPrice = totalUnitPrice;
          this.totalOffer = totalOffer;
          totalImpactValue = (totalOffer/totalUnitPrice) * 100;
          totalImpactValue = totalImpactValue.setScale(2);
          this.totalImpact = totalImpactValue + ' %';
        }
      
    }

    public class DataTableWrapper {

        public Integer counter { get; set; }
        public String userName { get; set;}
        public String action { get; set;}
        public String actionDate { get; set;}

        public DataTableWrapper(String action, Integer counter, String userName, String actionDate) {
          this.action = action;
          this.counter = counter;
          this.userName = userName;
          this.actionDate = actionDate;

        }
      
    }

    global List<String> attachmentsReqList{
        get{        
            List<String> attachmentsToDisplay = new List<String>();
            // map<id,id> contentDocumentParentId= new map<id,id>();

            String mainUrl = Utilities.getVFDomainURL();
            String attachmentUrl;

            for(ContentDocumentLink linkedDocs : [SELECT LinkedEntityId,ContentDocumentId  FROM ContentDocumentLink WHERE LinkedEntityId = :memoId ]){
                //contentDocumentParentId.put(linkedDocs.ContentDocumentId ,linkedDocs.LinkedEntityId);
                if (linkedDocs.ContentDocumentId != null) {
                    AttachmentFlag = true;
                }
                attachmentUrl = mainUrl + '/lightning/r/ContentDocument/' + linkedDocs.ContentDocumentId + '/view';
                attachmentsToDisplay.add(attachmentUrl);
            }

            // for(ContentVersion contentversionRecord :[SELECT Id,ContentDocumentId,Title,FileType,Description,LastModifiedById,LastModifiedDate FROM ContentVersion WHERE ContentDocumentId in :contentDocumentParentId.keySet() ]){
            //     attachmentsToDisplay.add(contentversionRecord);
            // }

            //select ContentDownloadUrl,DistributionPublicUrl, RelatedRecordId from ContentDistribution where ContentDocumentId = '0698E000002093kQAA'
            
            return  attachmentsToDisplay;
        }
        set;
    }
    
    global String NewLine {
        get { return '\r\n'; }
        set;
    }
}