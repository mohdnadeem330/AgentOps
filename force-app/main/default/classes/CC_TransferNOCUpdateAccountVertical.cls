global without sharing class CC_TransferNOCUpdateAccountVertical implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            List<HexaBPM__Service_Request__c> srRequest = [SELECT Id,BuyerName__c,HexaBPM__Customer__c,
                                                           (SELECT Id,Account__c FROM Partners__r ) FROM HexaBPM__Service_Request__c  WHERE id =: stp.HexaBPM__SR__c  limit 1 ];
            list<Id> accsToUpdate = new list<Id>();
            list<Account> accsListToUpdate = new list<Account>();
            for (HexaBPM__Service_Request__c nocSR : srRequest) {
                for (AgencyTeam__c secBuyer : nocSR.Partners__r) {
                    accsToUpdate.add(secBuyer.Account__c);
                }
                if(nocSR.BuyerName__c != null ){
                    accsToUpdate.add(nocSR.BuyerName__c);
                }
                if(nocSR.HexaBPM__Customer__c != null ){
                    accsToUpdate.add(nocSR.HexaBPM__Customer__c);
                }
                
                
            }
            for (Account accRecord : [SELECT Id,CustomerVertical__c FROM Account WHERE Id=:accsToUpdate]){
                Set<String> verticals = new Set<String>();
                
                if (accRecord.CustomerVertical__c != null) {
                    verticals.addAll(accRecord.CustomerVertical__c.split(';'));
                }else{
                    accRecord.CustomerVertical__c = 'Aldar Estates';
                    verticals.add('Aldar Estates');
                }
                if (!verticals.contains('Aldar Estates')) {
                    accRecord.CustomerVertical__c =  accRecord.CustomerVertical__c + ';Aldar Estates';
                }
                accsListToUpdate.add(accRecord);
                
            }
            if(!accsListToUpdate.isEmpty()){
                update accsListToUpdate;
            }
            
        } 
        catch(Exception e){ 
            Logger__c lgs = LoggerService.createApexLog(e,'CC_HandoverUpdateAccountVertical','CC_HandoverUpdateAccountVertical','EvaluateCustomCode');
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_UpdateTransferNOCAccountvertivcal';
            
        }
        return result;
    }
}