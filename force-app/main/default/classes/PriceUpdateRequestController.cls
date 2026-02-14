global with sharing class PriceUpdateRequestController {
    
    @AuraEnabled
    public static List<PriceUpdateRequest__c> createPriceUpdateReq(String comments, Map<String,String> newprice){
     List<PriceUpdateRequest__c> priceupdReq = new List<PriceUpdateRequest__c>();
        
       // try {
            PriceUpdateRequest__c pr = new  PriceUpdateRequest__c();
        
            pr.RequestedBy__c= UserInfo.getUserId() ;
            pr.RequestDate__c=System.Today();
            pr.RequestorComments__c=comments;
            priceupdReq.add(pr);
            if(priceupdReq.size()>0){
               

                List<PriceUpdateUnit__c> priceupdunit = new List<PriceUpdateUnit__c>();
               /* Map<Id,Integer> ids= new  Map<Id,Integer>();
                
                for(Map<String,Object> i:newprice ){
                    Id idd = Id.ValueOf((String)i.get('Id'));
                    Integer val = Integer.ValueOf(i.get('NewPrice'));
                    ids.put(Id.ValueOf((String)i.get('Id')),Integer.ValueOf(i.get('NewPrice')));
                } */
                Set<Id> IdSet = new Set<Id>();
                for(String i:newprice.keySet() ){
                    IdSet.add(Id.valueOf(i));
                }
                List<Unit__c> returnList = UnitService.getAllUnitsById(IdSet);
                
                //Added by Nikhil Mehra for PriceUpdateRequest
        		priceupdReq[0].CurrencyIsoCode = returnList[0].CurrencyIsoCode;
				insert priceupdReq;
                //Added by Nikhil Mehra for PriceUpdateRequest
                
                for(Unit__c u:returnList){
                    PriceUpdateUnit__c p=  new PriceUpdateUnit__c();
                    p.Project__c = u.Project__c;
                    p.Unit__c = u.Id;
                    p.Building__c = u.BuildingSectionName__c;
                    p.CurrentPrice__c = u.SellingPrice__c;
                    p.NewPrice__c = Decimal.valueOf(newprice.get(u.Id));
                    p.RequestNumber__c= priceupdReq[0].Id;
                    p.UnitStatus__c = u.Status__c;
                    p.CurrencyIsoCode = u.CurrencyIsoCode; // Added by Nikhil Mehra for PriceUpdateRequest
                    priceupdunit.add(p);
                }       
                if(priceupdunit.size()>0){
                    insert priceupdunit;

                    Approval.ProcessSubmitRequest approvalProcess = new Approval.ProcessSubmitRequest();
                    approvalProcess.setComments(comments);
                    approvalProcess.setObjectId(priceupdReq[0].Id);
                    approvalProcess.setSubmitterId(UserInfo.getUserId());
                    //Removed this for dynmaic execution of approval process by Nikhil Mehra
                    //approvalProcess.setProcessDefinitionNameOrId('SellingPriceApprovalProcessv4'); 
                    
                    Approval.ProcessResult result = Approval.process(approvalProcess);
                } else {
                    throw new AuraHandledException('Error, Please contact System Admin');        
                }
            }
       /* } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        } */
        return priceupdReq;
    }
    
    @AuraEnabled
    public static Map<String, String> getuUnitCodes(List<String> unitCodes){
        Map<String, String> unitCodeIdMap = new Map<String, String>();
        List<Unit__c> unitList = [SELECT
                                  ID,
                                  Name
                                  FROM
                                  Unit__c
                                  WHERE Name IN:unitCodes];
        if(!unitList.isEmpty()){
            for(Unit__c un: unitList){
                if(!unitCodeIdMap.containsKey(un.Name)){
                    unitCodeIdMap.put(un.Name, un.id);
                }
            }
        }
        return unitCodeIdMap;
    }
    @InvocableMethod(label='RevokeApprovalPriceUpdateRequest')
    webservice static void recallApproval(List<Id> recId)   
    {   
        try{    
            List<ProcessInstanceWorkitem> piwi = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recId];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Removed');       
            req.setWorkitemId(piwi.get(0).Id);
            Approval.process(req,false);
        }catch(DmlException ex){
            LoggerService.save(LoggerService.createApexLog(ex,'recallApproval','PriceUpdateRequestController','recallApproval'));
        }
    }
    @InvocableVariable
    public List<Id> recId;
}