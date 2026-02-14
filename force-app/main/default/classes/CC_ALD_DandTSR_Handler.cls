//Supporting class during Moving the External Councel or Submit for Court Case
//Block the Customer immediately and then check for the budget in case of External Councel
global without sharing class CC_ALD_DandTSR_Handler implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result = 'Success';
        String FLAG_CUSTOMER = 'Flag Customer';
        Map<Id, String> accIdBlockType = new Map<Id, String>();
        System.debug('#$#$ Invoked > ');
        Decimal dAndTBufferAmnt = Decimal.valueOf( system.label.DandTBufferAmount );

        try{
            Boolean flagUnflag = FALSE;
            if(stp == null || stp.HexaBPM__SR__c == null) {
                result='Invalid SR or SR Step';
            } else {
                HexaBPM__Service_Request__c sRRecord= [SELECT Id, LegalFees__c, InstallmentLine__c,InstallmentLine__r.Name, InstallmentLine__r.OutstandingAmount__c, SalesOrder__r.Status__c, 
                                                        HexaBPM__Customer__c, HexaBPM__Customer__r.ALDnT_Sub_Legal_Reason__c, SRType__c,SalesOrder__c,SalesOrder__r.Name
                                                        FROM HexaBPM__Service_Request__c 
                                                        WHERE Id = : stp.HexaBPM__SR__c  Limit 1];

                if(stp.HexaBPM__Summary__c.equalsIgnoreCase('Customer Negotiation')){
                    if( sRRecord != null && stp.HexaBPM__Step_Status__c.equalsIgnoreCase('Unit Cancelled') 
                        && String.isNotBlank(sRRecord.SalesOrder__c) && !sRRecord.SalesOrder__r.Status__c.equalsIgnoreCase('Cancelled') ){
                         result = 'Sales order must be Cancelled to perform this step';
                         return result;
                    }
                    if( sRRecord != null && String.isNotBlank( sRRecord.InstallmentLine__c) &&  sRRecord.InstallmentLine__r.OutstandingAmount__c > dAndTBufferAmnt ){
                         result = 'Clear outstanding amount';
                         return result;
                    }
                }

                if(sRRecord.SRType__c == Constants.DEFAULT_AND_TERMINATION) {
                    //Execute for DnT SR
                    sRRecord.LegalStatus__c = ALD_Constants.SENT_TO_EXTERNAL_COUNSEL;
                    update sRRecord;   
                    flagUnflag = TRUE;
                } else {
                    //LegalCourtOrder SR
                    //Execute for Court Order DnT SR
                    flagUnflag = stp.HexaBPM__Summary__c == FLAG_CUSTOMER ? true : false;
                    //If false, Try to Unblock the customer
                }
                System.debug('#$#$ sRRecord > '+sRRecord.Id);
                if(flagUnflag) {
                   	String SubFlagReason = sRRecord.SRType__c == Constants.DEFAULT_AND_TERMINATION ? '' : ALD_Constants.COURT_ORDER_FLAG;
                    System.debug('#$#$1. SubFlagReason > '+SubFlagReason);
                    //In case, the customer is already flagged due to Court order, then we need to retain the same.
                    SubFlagReason = sRRecord.HexaBPM__Customer__r.ALDnT_Sub_Legal_Reason__c == null ? SubFlagReason : sRRecord.HexaBPM__Customer__r.ALDnT_Sub_Legal_Reason__c;
                    System.debug('#$#$2. SubFlagReason > '+SubFlagReason);
                    accIdBlockType.put(sRRecord.HexaBPM__Customer__c, SubFlagReason);
                    blockCustomer(accIdBlockType);
                    // update SO Default to Legal...
                    Update new SalesOrder__c(Id = sRRecord.SalesOrder__c, HoldReasonCode__c='Legal '+sRRecord.InstallmentLine__r.Name+' '+sRRecord.SalesOrder__r.Name);
                } else {
                    
                    Id DandTRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.DEFAULT_AND_TERMINATION);

                    //If false, Try to Unblock the customer
                    set<Id> srSetVals = new set<Id>();
                    Set<Id> soIdSet = new set<Id>();
                    for(SalesOrder__c so:[SELECT Id, Account__c, HoldFlag__c, (Select Id, HexaBPM__Customer__c, HexaBPM__Customer__r.BlacklistReason__c  
                                                                               From ServiceRequests__r 
                                                                               Where RecordTypeId= :DandTRecordTypeId and HexaBPM__IsClosedStatus__c=false) 
                                          FROM SalesOrder__c 
                                          WHERE Account__c=:sRRecord.HexaBPM__Customer__c and Status__c!=:Constants.SO_STATUS_CANCELLED ]) 
                    {
                        soIdSet.add(so.Id);
                        for(HexaBPM__Service_Request__c srRec : so.ServiceRequests__r) {
                            srSetVals.add(srRec.Id);
                        }
                    }
                    system.debug('#$#$ Unflag the customer => '+srSetVals+' >> '+soIdSet);
                    ALD_DandTSR_Handler_CC.checkAndAutoUnflag(srSetVals, ALD_Constants.COURT_ORDER_FLAG , soIdSet);
                }
            }
        } catch(Exception e){result = e.getMessage()+'';}
        return result;
    }
    public static string blockCustomer(Map<Id, String> accIdBlockType) {
        System.debug('#$#$ accIdBlockType > '+accIdBlockType);
        string result = 'Success';
        List<Account> accToUpdate = new List<Account>();
        for(Id accId : accIdBlockType.keySet()) {
            accToUpdate.add(new Account(Id= accId , Blacklisted__c =true , BlacklistReason__c='Legal', ALDnT_Sub_Legal_Reason__c=accIdBlockType.get(accId)));
        }
        if(!accToUpdate.isEmpty()) {
            update accToUpdate;
        }
        return result;
    }
    
    public static string blockCustomerForDnT(Set<Id> accIds) {
        System.debug('#$#$ accIdBlockType > '+accIds);
        string result = 'Success';
        List<Account> accToUpdate = new List<Account>();
        for(Id accId : accIds) {
            accToUpdate.add(new Account(Id= accId , Blacklisted__c =true , BlacklistReason__c='Legal'));
        }
        if(!accToUpdate.isEmpty()) {
            update accToUpdate;
        }
        return result;
    }
}