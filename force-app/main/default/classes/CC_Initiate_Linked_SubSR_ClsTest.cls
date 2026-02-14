@isTest
public with sharing class CC_Initiate_Linked_SubSR_ClsTest {
    
     static testmethod void initiateLinkedSubSR(){
        
        HexaBPM__SR_Status__c objStatus = new HexaBPM__SR_Status__c();
        objStatus.Name = 'Draft';
        objStatus.HexaBPM__Code__c = 'DRAFT';
        insert objStatus;
     
     HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
         
        HexaBPM__SR_Template__c srTemplate1 = new HexaBPM__SR_Template__c();
        srTemplate1.Name = Constants.CHEQUE_REPLACEMENT_SR_TYPE;
        srTemplate1.HexaBPM__SR_RecordType_API_Name__c= 'PaymentExtension';
        insert srTemplate1;
         
        HexaBPM__SR_Template__c srTemplate = new HexaBPM__SR_Template__c();
        srTemplate.Name = 'Lease To Freehold Transfer';
        srTemplate.HexaBPM__SR_RecordType_API_Name__c='LeaseToFreeholdTransfer';
        insert srTemplate;
         
        Id recordTypeId;
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LeaseToFreeholdTransfer']){
            recordTypeId = rtype.Id;
        }
                 
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        List<HexaBPM__Service_Request__c> createdSrList = createSR(new List<HexaBPM__Service_Request__c>{new HexaBPM__Service_Request__c(RecordTypeId = recordTypeId,
                                                             HexaBPM__Customer__c= acc.id,
                                                             HexaBPM__SR_Template__c=srTemplate.id),new HexaBPM__Service_Request__c(RecordTypeId = recordTypeId,
                                                             HexaBPM__Customer__c= acc.id,
                                                             HexaBPM__SR_Template__c=srTemplate.id)});

        test.startTest();
            
            Map<Id,Id> srMap = new Map<Id,Id>();
            srMap.put(createdSrList[0].Id,createdSrList[1].Id);
            
            Set<Id> subSRId = new Set<Id>();
            subSRId.add(createdSrList[1].Id);
            
            Set<Id> setLinkedId = new Set<Id>();
            setLinkedId.add(createdSrList[1].Id);
        
            CC_Initiate_Linked_SubSR_Cls l1= new CC_Initiate_Linked_SubSR_Cls();
            l1.Initiate_SUB_LinkedSR(srMap, srMap, new map <id,id>(), new map <id,id>() ,subSRId,setLinkedId);
        test.stopTest();
    }
    
    static testmethod void initiateLinkedSubSR2(){
        
        HexaBPM__SR_Template__c srTemplate1 = new HexaBPM__SR_Template__c();
        srTemplate1.Name = Constants.CHEQUE_REPLACEMENT_SR_TYPE;
        srTemplate1.HexaBPM__SR_RecordType_API_Name__c= 'PaymentExtension';
        insert srTemplate1;

        
        HexaBPM__SR_Status__c objStatus = new HexaBPM__SR_Status__c();
        objStatus.Name = 'Submitted';
        objStatus.HexaBPM__Code__c = 'SUBMITTED';
        insert objStatus;
        
        HexaBPM__SR_Template__c srTemplate = new HexaBPM__SR_Template__c();
        srTemplate.Name = 'Lease To Freehold Transfer';
        srTemplate.HexaBPM__SR_RecordType_API_Name__c='LeaseToFreeholdTransfer';
        insert srTemplate;
                    
		Id recordTypeId;
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LeaseToFreeholdTransfer']){
            recordTypeId = rtype.Id;
        }
        
		Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;        
        List<HexaBPM__Service_Request__c> createdSrList = createSR(new List<HexaBPM__Service_Request__c>{new HexaBPM__Service_Request__c(RecordTypeId = recordTypeId,
                                                             HexaBPM__Customer__c= acc.id,
                                                             HexaBPM__SR_Template__c=srTemplate.id),new HexaBPM__Service_Request__c(RecordTypeId = recordTypeId,
                                                             HexaBPM__Customer__c= acc.id,
                                                             HexaBPM__SR_Template__c=srTemplate.id)});

        test.startTest();
            
            Map<Id,Id> srMap = new Map<Id,Id>();
            srMap.put(createdSrList[0].Id,createdSrList[1].Id);
            
            Set<Id> subSRId = new Set<Id>();
            subSRId.add(createdSrList[1].Id);
            
            Set<Id> setLinkedId = new Set<Id>();
            setLinkedId.add(createdSrList[1].Id);
        
            CC_Initiate_Linked_SubSR_Cls l1= new CC_Initiate_Linked_SubSR_Cls();
            l1.Initiate_SUB_LinkedSR(srMap, srMap, new map <id,id>(), new map <id,id>() ,subSRId,setLinkedId);
        test.stopTest();
    }
    
    public static List<HexaBPM__Service_Request__c> createSR(List<HexaBPM__Service_Request__c> srList){
        List<HexaBPM__Service_Request__c> createSrList = new List<HexaBPM__Service_Request__c>();

        for(HexaBPM__Service_Request__c thisRecord : srList){
            //TODO: popoulate required fields values
            HexaBPM__Service_Request__c srRecord = thisRecord.clone();
            srRecord=thisRecord.clone();
            srRecord.RecordTypeId = thisRecord.RecordTypeId;
            srRecord.HexaBPM__SR_Template__c = thisRecord.HexaBPM__SR_Template__c;
            srRecord.HexaBPM__Customer__c = thisRecord.HexaBPM__Customer__c; 
            srRecord.HexaBPM__Contact__c = thisRecord.HexaBPM__Contact__c; 
            srrecord.HexaBPM__Internal_SR_Status__c = thisRecord.HexaBPM__Internal_SR_Status__c;
            srrecord.HexaBPM__Parent_SR__c= thisRecord.HexaBPM__Parent_SR__c;
            srrecord.HexaBPM__Email__c='test@test.com';
            srrecord.HexaBPM__Send_SMS_to_Mobile__c='00971526127264';
            createSrList.add(srRecord);
        }
        if(!createSrList.isEmpty()){
            Database.insert(createSrList);
        }
        system.debug('#### Service Request Record Created = '+createSrList);
        return createSrList;   
    }
}