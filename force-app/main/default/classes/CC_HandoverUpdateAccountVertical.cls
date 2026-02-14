global without sharing class CC_HandoverUpdateAccountVertical implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            List<HexaBPM__Service_Request__c> srRequest = [ SELECT Id,SalesOrder__c,HexaBPM__Customer__c FROM HexaBPM__Service_Request__c  WHERE id =: stp.HexaBPM__SR__c limit 1 ];
            List<SalesOrder__c> SO = [ SELECT Id,Account__c,(SELECT Id,Name,Account__c FROM Joint_OwnersSalesOrder__r ) FROM SalesOrder__c  WHERE id=:srRequest[0].SalesOrder__c limit 1  ];
            list<Id> jointOwnerIds = new list<Id>();
            list<Account> accsListToUpdate = new list<Account>();
            for (SalesOrder__c handoverSO : SO ) {
                for (JointOwner__c singleJO : handoverSO.Joint_OwnersSalesOrder__r) {
                    jointOwnerIds.add(singleJO.Account__c);
                }
                
            }
            if(srRequest[0].HexaBPM__Customer__c != null ){
                jointOwnerIds.add(srRequest[0].HexaBPM__Customer__c);
            }
            for (Account accRecord : [SELECT Id,CustomerVertical__c FROM Account WHERE Id=:jointOwnerIds]){
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
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_HandoverUpdateAccountVertical';
        }
        return result;
    }
}