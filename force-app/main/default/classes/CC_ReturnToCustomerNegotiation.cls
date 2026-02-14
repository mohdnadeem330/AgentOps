global without sharing class CC_ReturnToCustomerNegotiation implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
		boolean isUpdateSOToDefault = true;
		boolean isUpdateAccToDefault = true;
		List<SObject> recordsToUpdate = new List<SObject>();
		List<SalesOrder__c> soUpdateList = new List<SalesOrder__c>();
		List<Account> accUpdateList = new List<Account>();
        try{
            
            if(stp.HexaBPM__SR__c == null){
                result='CC_ReturnToCustomerNegotiation: Invalid SR or SR Step';
            }else{                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Name,HexaBPM__Customer__c, RecordTypeId, HexaBPM__Internal_Status_Name__c,HexaBPM__Internal_SR_Status__c, SalesOrder__c,
                                                        SyncStatus__c,  SalesOrder__r.Account__c,SalesOrder__r.HoldReasonCode__c, HexaBPM__Customer__r.BlacklistReason__c, HexaBPM__Customer__r.Blacklisted__c
                                                        FROM HexaBPM__Service_Request__c 
                                                        WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                
                if (sRRecord != null && sRRecord.SalesOrder__c != null && sRRecord.SalesOrder__r.Account__c != null ) {
						List<HexaBPM__Service_Request__c> SRList = [SELECT Id, HexaBPM__External_Status_Name__c, SalesOrder__c,HexaBPM__Customer__c,
                                                            SalesOrder__r.HoldFlag__c, SalesOrder__r.HoldReasonCode__c,HexaBPM__Internal_Status_Name__c,
                                                            HexaBPM__Customer__r.BlacklistReason__c, HexaBPM__Customer__r.Blacklisted__c
                                                            FROM HexaBPM__Service_Request__c 
                                                            WHERE HexaBPM__Customer__c =: sRRecord.SalesOrder__r.Account__c
                                                            AND SRType__c = : Constants.DEFAULT_AND_TERMINATION
                                                            AND SalesOrder__r.HoldFlag__c = true];
															
						for(HexaBPM__Service_Request__c srObj : SRList ){
                                if( sRRecord.SalesOrder__c.equals(srObj.SalesOrder__c) &&  srObj.HexaBPM__Internal_Status_Name__c.equalsIgnoreCase( ALD_Constants.SENT_TO_EXTERNAL_COUNSEL )){
								isUpdateSOToDefault = false;
								break;
							}
							if(sRRecord.SalesOrder__r.Account__c.equals( srObj.HexaBPM__Customer__c ) && srObj.HexaBPM__Internal_Status_Name__c.equalsIgnoreCase( ALD_Constants.SENT_TO_EXTERNAL_COUNSEL )){
								isUpdateAccToDefault = false;
								break;
							}
						}	
						if(isUpdateSOToDefault){
							soUpdateList.add( new SalesOrder__c( Id = sRRecord.SalesOrder__c, HoldReasonCode__c = sRRecord.SalesOrder__r.HoldReasonCode__c.replaceAll('(?i)Legal', 'Default')));
							recordsToUpdate.addAll(soUpdateList);
							if(isUpdateAccToDefault){
								accUpdateList.add(new account(Id = sRRecord.SalesOrder__r.Account__c, BlacklistReason__c = 'Default', Blacklisted__c = false));
								recordsToUpdate.addAll(accUpdateList);
							}

                            if(recordsToUpdate.size() > 0){
                                update recordsToUpdate;  
                            }       
						}
						
                   }
            }
            return result;                                        
        }
        catch(exception ex){
            return result;
        }
    }
}