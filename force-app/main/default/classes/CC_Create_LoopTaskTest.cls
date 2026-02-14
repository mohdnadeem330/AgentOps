@istest
public class CC_Create_LoopTaskTest {
   
    @testSetup static void TestData() {
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        TestObjectsFactory.ResponseWrapper initDataWrapper =  TestObjectsFactory.createInitialData('BI_CMI','Banking and Insurance','Banking and Insurance');
        try{
            TestObjectsFactory.ResponseWrapper srDataWrapper =  TestObjectsFactory.createSrData('AgencyRegistration','Banking and Insurance',
                                                                                                initDataWrapper.acc.Id,'General_Information_for_Regulated_Activities');
        } catch(Exception e){
            
        }
       
       
        Contact objCon = new Contact();
        objCon.LastName = 'Test';
        objCon.FirstName = 'Test';
        objCon.Email = 'TestEmail@fsra.com';
        objCon.AccountId = initDataWrapper.acc.Id;
        insert objCon;
       
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        for(HexaBPM__Service_Request__c objSR:[Select Id,Name,HexaBPM__Customer__c,HexaBPM__Send_SMS_to_Mobile__c,HexaBPM__Contact__c from HexaBPM__Service_Request__c limit 1]){
            SR = objSR;
            SR.HexaBPM__Contact__c = objCon.Id;
        }
        update SR;
    }
   
    public static testmethod void method11(){
        Profile profile2 = [Select Id from Profile where name = 'System Administrator'];
        Integer rand = Math.round(Math.random() * 1000);
        string randomFourDigit=String.valueOf(Math.mod(rand, 9999)).leftpad(4, '0');
        User portalAccountOwner2 = new User(ProfileId = profile2.Id,Username = System.now().millisecond() + randomFourDigit+'testx1@test.com',
        Alias = 'batman',Email='bruce.wayne@fsra.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner2);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
        HexaBPM__SR_Template__c objsrtemlate1 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
        objsrtemlate1.HexaBPM__Portal_Service_Request_Name__c = 'test';
        objsrtemlate1.HexaBPM__SR_RecordType_API_Name__c= 'General';
        objsrtemlate1.HexaBPM__Do_not_use_owner__c=false;
        objsrtemlate1.ownerid = UserInfo.getUserId();
        insert objsrtemlate1;
         
        HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
        ST3.HexaBPM__Code__c = 'REGISTRAR_REVIEW2';
        ST3.HexaBPM__Step_RecordType_API_Name__c= 'General';
        Insert ST3;        
         
      HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.HexaBPM__Customer__c  = a1.Id;
        SR1.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR1.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';
        insert SR1;
         
       HexaBPM__Action__c Action1 = New HexaBPM__Action__c();
          Action1.HexaBPM__Field_Value__c = '30.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action1;
         
       HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name ='Awaiting Approval';
            status1.HexaBPM__Code__c ='AWAITING_APPROVAL2';
           // status1.HexaBPM__DEV_Id__c ='567890';
            insert status1;
           
             
         Group testGroup1 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup1;
         
         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue1 = new QueueSObject(QueueID = testGroup1.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue1;
         }
        
        Group testGroup2 = new Group(Name='Test User', Type='Queue');
         insert testGroup2;
         
         GroupMember Gm2 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup2.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue2 = new QueueSObject(QueueID = testGroup2.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue2;
         }

         map<Id,string> mapSRStepQueues1 = new map<Id,string>();
        mapSRStepQueues1.put(testgroup1.id,'Client Entry User');
        map<string,Id> mapStepRecType1 = new map<string,Id>();
        Id rtId = Schema.SObjectType.HexaBPM__Step__c.RecordTypeInfosByName.get('General').RecordTypeId;
        //mapStepRecType1.put('General','0123E0000004JnP');
        mapStepRecType1.put('General',rtId);
         
          HexaBPM__SR_Steps__c SRS11 = new HexaBPM__SR_Steps__c();
             SRS11.HexaBPM__Step_No__c =30.0;
             srs11.HexaBPM__Do_not_use_owner__c=false;
             SRS11.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS11.HexaBPM__Step_Template__c = ST3.id;
             SRS11.HexaBPM__Start_Status__c = status1.id;
             SRS11.HexaBPM__SR_Template__c = objsrtemlate1.ID;
             SRS11.ownerid = UserInfo.getUserId();
             SRS11.HexaBPM__Estimated_Hours__c = 10;
             insert SRS11;
      HexaBPM__SR_Steps__c SRS12 = new HexaBPM__SR_Steps__c();
             SRS12.HexaBPM__Step_No__c =30.0;
             SRS12.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS12.HexaBPM__Step_Template__c = ST3.id;
             SRS12.HexaBPM__Start_Status__c = status1.id;
             SRS12.HexaBPM__SR_Template__c = objsrtemlate1.ID;
             SRS12.ownerid = UserInfo.getUserId();
             SRS12.HexaBPM__Estimated_Hours__c = 10;
             insert SRS12;
             
             HexaBPM__SR_Steps__c SRS51 = new HexaBPM__SR_Steps__c();
         SRS51.HexaBPM__Step_No__c =30.0;
         srs51.HexaBPM__Do_not_use_owner__c=false;
         SRS51.HexaBPM__Step_Template__c = ST3.id;
         SRS51.HexaBPM__Start_Status__c = status1.id;
         SRS51.ownerid = testGroup1.id;
         insert SRS51;
           
        HexaBPM__Step__c St11 = new  HexaBPM__Step__c();
             st11.HexaBPM__Step_No__c =30.0;
             st11.HexaBPM__SR__c = SR1.id;
             st11.HexaBPM__Step_Template__c = ST3.id;
             st11.HexaBPM__Status__c = status1.id;
             st11.HexaBPM__SR_Step__c = SRS11.id;
             st11.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st11.HexaBPM__Step_Notes__c = 'test area';
             //sT11.OWNERID = '0053E000000HFrh';
             ST11.ownerid = testGroup2.id;
             insert St11;
             //ST11.recordtypeid='0123E0000004JnP';
             update st11;
             
             HexaBPM__Step__c St12 = new  HexaBPM__Step__c();
             st12.HexaBPM__Step_No__c =30.0;
             st12.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
           
             //ST12.recordtype.developername = 'General';
             //ST12.recordtypeid='0123E0000004JnP';
             st12.HexaBPM__SR__c = SR1.id;
             st12.HexaBPM__Step_Template__c = ST3.id;
             st12.HexaBPM__Status__c = status1.id;
             st12.HexaBPM__SR_Step__c = SRS12.id;
             st12.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st12.HexaBPM__Step_Notes__c = 'test area';
             //sT12.OWNERID = '0053E000000HFrh';
             ST12.ownerid = testGroup2.id;
             insert St12;
         
                     
       
         
       
         
     
         
         
       Contact con1 = new Contact();
         con1.AccountId = a1.Id;
         con1.email = 'test@gmail.com';
         con1.FirstName =  'Fname';
         con1.LastName = 'LName';
         insert con1;
       
       
        list<HexaBPM__Step__c> lstExistingSteps1 = new list<HexaBPM__Step__c>();
        lstExistingSteps1.add(St11);
        map<string,Id> mapStepQueues1 =  new map<string,Id>();
        map<Id,string> mapStepTemplateQueues1 = new map<Id,string>();
       
        map<Id,string> mapSRTemplateQueues1 = new map<Id,String>();
            map<id,id> mapSROwner1 = new map<id,id>();
            map<id,string> mapUserLicense1 = new map<id,string>();

            list<HexaBPM__SR_Steps__c> lstSRSteps1 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps1.add(SRS11);
           
     
   
 
        try{CC_Create_LoopTask LoopTask1 = new CC_Create_LoopTask();
      LoopTask1.GenerateLoopTask(lstExistingSteps1,mapStepQueues1,mapStepTemplateQueues1,mapSRStepQueues1,mapSRTemplateQueues1,
                                 mapSROwner1,mapUserLicense1,mapStepRecType1,lstSRSteps1,Action1,St11);} 
        catch(Exception e){}
                               
         
}
   
    public static testmethod void method12()
     {
     Profile profile2 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner2 = new User(ProfileId = profile2.Id,Username = System.now().millisecond() + 'testx2@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner2);
       
      Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
      HexaBPM__SR_Template__c objsrtemlate1 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate1.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate1.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate1.HexaBPM__Do_not_use_owner__c=false;
         objsrtemlate1.ownerid = UserInfo.getUserId();
         insert objsrtemlate1;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
        // ST3.HexaBPM__DEV_Id__c = 'testdev';
         ST3.HexaBPM__Code__c = 'REGISTRAR_REVIEW2';
         ST3.HexaBPM__Step_RecordType_API_Name__c= 'General';
      Insert ST3;        
         
      HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.HexaBPM__Customer__c  = a1.Id;
      //SR.Sys_License_Application__c = l1.Id;
        SR1.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR1.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR1;
         
       HexaBPM__Action__c Action1 = New HexaBPM__Action__c();
          Action1.HexaBPM__Field_Value__c = '30.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action1;
         
       HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name ='Awaiting Approval';
            status1.HexaBPM__Code__c ='AWAITING_APPROVAL2';
           // status1.HexaBPM__DEV_Id__c ='567890';
            insert status1;
           
             
         Group testGroup1 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup1;
         
         GroupMember Gm1 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup1.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue1 = new QueueSObject(QueueID = testGroup1.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue1;
         }
         
         Group testGroup2 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup2;
         
         GroupMember Gm2 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup2.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue2 = new QueueSObject(QueueID = testGroup2.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue2;
         }

         map<Id,string> mapSRStepQueues1 = new map<Id,string>();
        mapSRStepQueues1.put(testgroup1.id,'Client Entry User');
        map<string,Id> mapStepRecType1 = new map<string,Id>();
        Id rtId = Schema.SObjectType.HexaBPM__Step__c.RecordTypeInfosByName.get('General').RecordTypeId;
        //mapStepRecType1.put('General','0123E0000004JnP');
        mapStepRecType1.put('General',rtId);
         
          HexaBPM__SR_Steps__c SRS11 = new HexaBPM__SR_Steps__c();
             SRS11.HexaBPM__Step_No__c =30.0;
             srs11.HexaBPM__Do_not_use_owner__c=true;
             SRS11.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS11.HexaBPM__Step_Template__c = ST3.id;
             SRS11.HexaBPM__Start_Status__c = status1.id;
             SRS11.HexaBPM__SR_Template__c = objsrtemlate1.ID;
             SRS11.HexaBPM__SR_Template__r = srTemp;
             //SRS11.ownerid ='0053E000000HFrh';
             SRS11.ownerid = UserInfo.getUserId();
             SRS11.HexaBPM__Estimated_Hours__c = 10;
             insert SRS11;
         
          HexaBPM__SR_Steps__c SRS12 = new HexaBPM__SR_Steps__c();
             SRS12.HexaBPM__Step_No__c =30.0;
             SRS12.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS12.HexaBPM__Step_Template__c = ST3.id;
             SRS12.HexaBPM__Start_Status__c = status1.id;
             SRS12.HexaBPM__SR_Template__c = objsrtemlate1.ID;
             //SRS12.ownerid ='0053E000000HFrh';
             SRS12.ownerid = UserInfo.getUserId();
             SRS12.HexaBPM__Estimated_Hours__c = 10;
             insert SRS12;
           
        HexaBPM__Step__c St11 = new  HexaBPM__Step__c();
             st11.HexaBPM__Step_No__c =30.0;
             st11.HexaBPM__SR__c = SR1.id;
             st11.HexaBPM__Step_Template__c = ST3.id;
             st11.HexaBPM__Status__c = status1.id;
             st11.HexaBPM__SR_Step__c = SRS11.id;
             //st11.HexaBPM__SR_Step__r=srStep;
             st11.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st11.HexaBPM__Step_Notes__c = 'test area';
             //sT11.OWNERID = '0053E000000HFrh';
             ST11.ownerid = testGroup2.Id;
             insert St11;
             //ST11.recordtypeid='0123E0000004JnP';
             update st11;
             
         
       HexaBPM__Step__c St12 = new  HexaBPM__Step__c();
             st12.HexaBPM__Step_No__c =30.0;
             st12.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
           
             //ST12.recordtype.developername = 'General';
             //ST12.recordtypeid='0123E0000004JnP';
             st12.HexaBPM__SR__c = SR1.id;
             st12.HexaBPM__Step_Template__c = ST3.id;
             st12.HexaBPM__Status__c = status1.id;
             st12.HexaBPM__SR_Step__c = SRS12.id;
             st12.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st12.HexaBPM__Step_Notes__c = 'test area';
             //sT12.OWNERID = '0053E000000HFrh';
             ST12.ownerid = testGroup2.Id;
             insert St12;                
       
         
       
         
     
         
         
       Contact con1 = new Contact();
         con1.AccountId = a1.Id;
         con1.email = 'test@gmail.com';
         con1.FirstName =  'Fname';
         con1.LastName = 'LName';
         insert con1;
       
       
        list<HexaBPM__Step__c> lstExistingSteps1 = new list<HexaBPM__Step__c>();
        lstExistingSteps1.add(St11);
        map<string,Id> mapStepQueues1 =  new map<string,Id>();
        map<Id,string> mapStepTemplateQueues1 = new map<Id,string>();
       
        map<Id,string> mapSRTemplateQueues1 = new map<Id,String>();
            map<id,id> mapSROwner1 = new map<id,id>();
            map<id,string> mapUserLicense1 = new map<id,string>();

            list<HexaBPM__SR_Steps__c> lstSRSteps1 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps1.add(SRS11);
           
     
   
 
         try{CC_Create_LoopTask LoopTask1 = new CC_Create_LoopTask();
      LoopTask1.GenerateLoopTask(lstExistingSteps1,mapStepQueues1,mapStepTemplateQueues1,mapSRStepQueues1,mapSRTemplateQueues1,
                                mapSROwner1,mapUserLicense1,mapStepRecType1,lstSRSteps1,Action1,St11);
            } catch(Exception e){}
         
}

    public static testmethod void method13()
     {
     Profile profile2 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner2 = new User(ProfileId = profile2.Id,Username = System.now().millisecond() + 'testx3@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner2);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
      HexaBPM__SR_Template__c objsrtemlate1 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate1.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate1.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate1.HexaBPM__Do_not_use_owner__c=true;
         objsrtemlate1.ownerid = UserInfo.getUserId();
         insert objsrtemlate1;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
         ST3.HexaBPM__Code__c = 'REGISTRAR_REVIEW2';
         ST3.HexaBPM__Step_RecordType_API_Name__c= 'General';
         ST3.ownerid = UserInfo.getUserId();
      Insert ST3;        
         
         HexaBPM__Step_Template__c stepTemp=[select id,ownerid,HexaBPM__Step_RecordType_API_Name__c from HexaBPM__Step_Template__c limit 1];
         
      HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.HexaBPM__Customer__c  = a1.Id;
        SR1.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR1.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR1;
         
       HexaBPM__Action__c Action1 = New HexaBPM__Action__c();
          Action1.HexaBPM__Field_Value__c = '30.0';
          insert Action1;
         
       HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name ='Awaiting Approval';
            status1.HexaBPM__Code__c ='AWAITING_APPROVAL2';
           // status1.HexaBPM__DEV_Id__c ='567890';
            insert status1;
           
             
         Group testGroup1 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup1;
         
         GroupMember Gm1 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup1.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue1 = new QueueSObject(QueueID = testGroup1.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue1;
         }
         
         Group testGroup2 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup2;
         
         GroupMember Gm2 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup2.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue2 = new QueueSObject(QueueID = testGroup2.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue2;
         }

         map<Id,string> mapSRStepQueues1 = new map<Id,string>();
        mapSRStepQueues1.put(testgroup1.id,'Client Entry User');
        map<string,Id> mapStepRecType1 = new map<string,Id>();
        Id rtId = Schema.SObjectType.HexaBPM__Step__c.RecordTypeInfosByName.get('General').RecordTypeId;
        mapStepRecType1.put('General',rtId);
         
          HexaBPM__SR_Steps__c SRS11 = new HexaBPM__SR_Steps__c();
             SRS11.HexaBPM__Step_No__c =30.0;
             srs11.HexaBPM__Do_not_use_owner__c=false;
             SRS11.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS11.HexaBPM__Step_Template__c = ST3.id;
             SRS11.HexaBPM__Step_Template__r = stepTemp;
             SRS11.HexaBPM__Start_Status__c = status1.id;
             SRS11.HexaBPM__SR_Template__r = srTemp;
             SRS11.ownerid = UserInfo.getUserId();
             for(QueuesObject queue:[Select QueueId from QueuesObject where SObjectType='HexaBPM__SR_Steps__c']){
                SRS11.ownerid = queue.QueueId;
             }
             SRS11.HexaBPM__Estimated_Hours__c = 10;
             insert SRS11;
         
          HexaBPM__SR_Steps__c SRS12 = new HexaBPM__SR_Steps__c();
             SRS12.HexaBPM__Step_No__c =30.0;
             SRS12.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS12.HexaBPM__Step_Template__c = ST3.id;
             SRS12.HexaBPM__Start_Status__c = status1.id;
             SRS12.HexaBPM__SR_Template__c = objsrtemlate1.ID;
             SRS12.HexaBPM__SR_Template__r = srTemp;
             //SRS12.ownerid ='0053E000000HFrh';
             SRS12.ownerid = UserInfo.getUserId();
             SRS12.HexaBPM__Estimated_Hours__c = 10;
             insert SRS12;
           
        HexaBPM__Step__c St11 = new  HexaBPM__Step__c();
             st11.HexaBPM__Step_No__c =30.0;
             st11.HexaBPM__SR__c = SR1.id;
             st11.HexaBPM__Step_Template__c = ST3.id;
             st11.HexaBPM__Status__c = status1.id;
             st11.HexaBPM__SR_Step__c = SRS11.id;
             //st11.HexaBPM__SR_Step__r=srStep;
             st11.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st11.HexaBPM__Step_Notes__c = 'test area';
             //sT11.OWNERID = '0053E000000HFrh';
             ST11.ownerid = testGroup2.Id;
             insert St11;
             //ST11.recordtypeid='0123E0000004JnP';
             update st11;
             
         
       HexaBPM__Step__c St12 = new  HexaBPM__Step__c();
             st12.HexaBPM__Step_No__c =30.0;
             st12.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
           
             //ST12.recordtype.developername = 'General';
             //ST12.recordtypeid='0123E0000004JnP';
             st12.HexaBPM__SR__c = SR1.id;
             st12.HexaBPM__Step_Template__c = ST3.id;
             st12.HexaBPM__Status__c = status1.id;
             st12.HexaBPM__SR_Step__c = SRS12.id;
             st12.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st12.HexaBPM__Step_Notes__c = 'test area';
             //sT12.OWNERID = '0053E000000HFrh';
             ST12.ownerid = testGroup2.Id;
             insert St12;                
       
         
       
         
     
         
         
       Contact con1 = new Contact();
         con1.AccountId = a1.Id;
         con1.email = 'test@gmail.com';
         con1.FirstName =  'Fname';
         con1.LastName = 'LName';
         insert con1;
       
       
        list<HexaBPM__Step__c> lstExistingSteps1 = new list<HexaBPM__Step__c>();
        lstExistingSteps1.add(St11);
        map<string,Id> mapStepQueues1 =  new map<string,Id>();
        map<Id,string> mapStepTemplateQueues1 = new map<Id,string>();
       
        map<Id,string> mapSRTemplateQueues1 = new map<Id,String>();
            map<id,id> mapSROwner1 = new map<id,id>();
            map<id,string> mapUserLicense1 = new map<id,string>();

            list<HexaBPM__SR_Steps__c> lstSRSteps1 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps1.add(SRS11);
           
     
   
 
      /*CC_Create_LoopTask LoopTask1 = new CC_Create_LoopTask();
      LoopTask1.GenerateLoopTask(lstExistingSteps1,mapStepQueues1,mapStepTemplateQueues1,mapSRStepQueues1,mapSRTemplateQueues1,
                                mapSROwner1,mapUserLicense1,mapStepRecType1,lstSRSteps1,Action1,St11);*/
                               
         
}

    public static testmethod void method111()
     {
        Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
         Integer rand = Math.round(Math.random() * 1000);
        string randomFourDigit=String.valueOf(Math.mod(rand, 9999)).leftpad(4, '0');
        User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() + randomFourDigit+'testx4@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
          Group testGroup11 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=false;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid = UserInfo.getUserId();
         insert objsrtemlate11;
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
      Insert ST31;        
     
     
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Client Entry User');
        Group testGroup111 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Client Entry User',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=false;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
     
   
 
      CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
                               
         
}

    public static testmethod void method121()
     {
     Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() + 'testx5@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
          Group testGroup11 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }
         
         Group testGroup12 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup12;
         
         GroupMember Gm12 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup12.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue12 = new QueueSObject(QueueID = testGroup12.id, SObjectType = 'HexaBPM__SR_Template__c');
         insert testQueue12;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=false;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid =testGroup12.id;
         insert objsrtemlate11;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
      Insert ST31;        
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Client Entry User');
        Group testGroup111 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Client Entry User',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=true;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.HexaBPM__SR_Template__r = srTemp;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             SRS121.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
       
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
        mapSRTemplateQueues11.put(testgroup11.id,'Client Entry User');
       
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
         try{CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
            } Catch(Exception e){
                
            }                      
         
}

    public static testmethod void method131()
     {
       
        Id recordTypeId=Schema.SobjectType.HexaBPM__Step__c.getRecordTypeInfosByName().get('General').getRecordTypeID();
       
     Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() + 'testx6@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
        Group testGroup11 = new Group(Name='Client Entry User', Type='Queue');
        insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }
         
         Group testGroup12 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup12;
         
         GroupMember Gm12 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup12.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue12 = new QueueSObject(QueueID = testGroup12.id, SObjectType = 'HexaBPM__SR_Template__c');
         insert testQueue12;
         }
         
         Group testGroup13 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup13;
         
         GroupMember Gm13 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup13.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue13 = new QueueSObject(QueueID = testGroup13.id, SObjectType = 'HexaBPM__Step_Template__c');
         insert testQueue13;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=true;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid =testGroup12.id;
         insert objsrtemlate11;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
         ST31.ownerid=testGroup13.id;
         
      Insert ST31;        
     
      HexaBPM__Step_Template__c stepTemp=[select id,ownerid,HexaBPM__Step_RecordType_API_Name__c from HexaBPM__Step_Template__c limit 1];
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Client Entry User');
        Group testGroup111 = new Group(Name='Client Entry User', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Client Entry User',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=true;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Step_Template__r = stepTemp;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             SRS111.HexaBPM__SR_Template__r = srTemp;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             SRS121.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
       
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        mapStepTemplateQueues11.put(testgroup11.id,'Client Entry User');
       
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
        mapSRTemplateQueues11.put(testgroup11.id,'Client Entry User');
       
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
           
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            mapStepRecType11.put('General',recordTypeId);
           
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
     
   
 
         try{CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
            } catch(Exception e){}   
         
}
    public static testmethod void method111else()
     {
     Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
         Integer rand = Math.round(Math.random() * 1000);
        string randomFourDigit=String.valueOf(Math.mod(rand, 9999)).leftpad(4, '0');
     User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() +randomFourDigit+ 'testx7@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
        Group testGroup11 = new Group(Name='Test', Type='Queue');
        insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=false;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid = UserInfo.getUserId();
         insert objsrtemlate11;
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
      Insert ST31;        
     
     
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Test');
        Group testGroup111 = new Group(Name='Test', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Test',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=false;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             SRS121.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
     
   
 
      CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
                               
         
}

    public static testmethod void method121else()
     {
     Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() + 'testx8@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
       
        Group testGroup11 = new Group(Name='Test', Type='Queue');
        insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }
         
         Group testGroup12 = new Group(Name='Test', Type='Queue');
         insert testGroup12;
         
         GroupMember Gm12 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup12.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue12 = new QueueSObject(QueueID = testGroup12.id, SObjectType = 'HexaBPM__SR_Template__c');
         insert testQueue12;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=false;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid =testGroup12.id;
         insert objsrtemlate11;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
      Insert ST31;        
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Test');
        Group testGroup111 = new Group(Name='Test', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Test',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=true;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             SRS111.HexaBPM__SR_Template__r = srTemp;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             SRS121.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
       
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
        mapSRTemplateQueues11.put(testgroup11.id,'Test');
       
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
     
   
 
         Try {CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
                                } catch(Exception e){}   
           
         
}

    public static testmethod void method131else()
     {
       
        Id recordTypeId=Schema.SobjectType.HexaBPM__Step__c.getRecordTypeInfosByName().get('General').getRecordTypeID();
       
     Profile profile21 = [Select Id from Profile where name = 'System Administrator'];
     User portalAccountOwner21 = new User(ProfileId = profile21.Id,Username = System.now().millisecond() + 'testx9@test.com',
        Alias = 'batman',Email='bruce.wayne@wayneenterprises.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
        Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner21);
       
        Account a1 = new Account();
        for(Account acc:[Select Id,Name from Account limit 1]){
            a1 = acc;
        }
          Group testGroup11 = new Group(Name='Test', Type='Queue');
         insert testGroup11;
         
         GroupMember Gm11 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup11.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue11 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__SR_Steps__c');
         insert testQueue11;
         }
         
         Group testGroup12 = new Group(Name='Test', Type='Queue');
         insert testGroup12;
         
         GroupMember Gm12 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup12.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue12 = new QueueSObject(QueueID = testGroup12.id, SObjectType = 'HexaBPM__SR_Template__c');
         insert testQueue12;
         }
         
         Group testGroup13 = new Group(Name='Test', Type='Queue');
         insert testGroup13;
         
         GroupMember Gm13 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup13.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue13 = new QueueSObject(QueueID = testGroup13.id, SObjectType = 'HexaBPM__Step_Template__c');
         insert testQueue13;
         }

      HexaBPM__SR_Template__c objsrtemlate11 = new HexaBPM__SR_Template__c(name = 'LPC Waiver');
         objsrtemlate11.HexaBPM__Portal_Service_Request_Name__c = 'test';
         objsrtemlate11.HexaBPM__SR_RecordType_API_Name__c= 'General';
         objsrtemlate11.HexaBPM__Do_not_use_owner__c=true;
         //objsrtemlate11.ownerid = '0053E000000HFrh';
         objsrtemlate11.ownerid =testGroup12.id;
         insert objsrtemlate11;
         
         HexaBPM__SR_Template__c srTemp=[select id,ownerid,HexaBPM__Do_not_use_owner__c from HexaBPM__SR_Template__c limit 1];
         
      HexaBPM__Step_Template__c ST31 = new HexaBPM__Step_Template__c(name = 'Registrar Review');
       //  ST31.HexaBPM__DEV_Id__c = 'testdev';
         ST31.HexaBPM__Code__c = 'REGISTRAR_REVIEW3';
         ST31.HexaBPM__Step_RecordType_API_Name__c= 'General';
         ST31.ownerid=testGroup13.id;
         
      Insert ST31;        
     
      HexaBPM__Step_Template__c stepTemp=[select id,ownerid,HexaBPM__Step_RecordType_API_Name__c from HexaBPM__Step_Template__c limit 1];
         
      HexaBPM__Service_Request__c SR11 = new HexaBPM__Service_Request__c();
        SR11.HexaBPM__Customer__c  = a1.Id;
        SR11.HexaBPM__Ultimate_SR_Menu_Text__c = 'Company Services';
      //SR.Sys_License_Application__c = l1.Id;
        SR11.HexaBPM__Email__c = 'test@fsraconnect.com';
        SR11.HexaBPM__Send_SMS_to_Mobile__c= '00971666666666';

        insert SR11;
         
       HexaBPM__Action__c Action11 = New HexaBPM__Action__c();
          Action11.HexaBPM__Field_Value__c = '73.0';
          //Action.HexaBPM__Step_Template__c = SRT.id;
          insert Action11;
         
       HexaBPM__Status__c status11 = new HexaBPM__Status__c();
            status11.Name ='Awaiting Approval';
            status11.HexaBPM__Code__c ='AWAITING_APPROVAL3';
          //  status11.HexaBPM__DEV_Id__c ='567890';
            insert status11;
           
         map<Id,string> mapSRStepQueues11 = new map<Id,string>();
        mapSRStepQueues11.put(testgroup11.id,'Test');
        Group testGroup111 = new Group(Name='Test', Type='Queue');
         insert testGroup111;
         
         GroupMember Gm111 = new GroupMember(UserOrGroupid = UserInfo.getUserId(),GroupId=testGroup111.id);

         System.runAs(new User(Id=UserInfo.getUserId()))
         {
         QueuesObject testQueue111 = new QueueSObject(QueueID = testGroup11.id, SObjectType = 'HexaBPM__Step__c');
         insert testQueue111;
         }
         map<string,Id> mapStepQueues11 =  new map<string,Id>();
        mapStepQueues11.put('Test',testgroup11.id);
       
       HexaBPM__SR_Steps__c SRS111 = new HexaBPM__SR_Steps__c();
             SRS111.HexaBPM__Step_No__c =73.0;
             SRS111.HexaBPM__Do_not_use_owner__c=true;
             //SRS111.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS111.HexaBPM__Step_Template__c = ST31.id;
             SRS111.HexaBPM__Step_Template__r = stepTemp;
             SRS111.HexaBPM__Start_Status__c = status11.id;
             SRS111.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             SRS111.HexaBPM__SR_Template__r = srTemp;
             SRS111.ownerid = testgroup11.id;
             insert SRS111;
      HexaBPM__SR_Steps__c SRS121 = new HexaBPM__SR_Steps__c();
             SRS121.HexaBPM__Step_No__c =73.0;
             //SRS121.HexaBPM__Step_RecordType_API_Name__c = 'General';
             SRS121.HexaBPM__Step_Template__c = ST31.id;
             SRS121.HexaBPM__Start_Status__c = status11.id;
             SRS121.HexaBPM__SR_Template__c = objsrtemlate11.ID;
             //SRS121.ownerid ='0053E000000HFrh';
             SRS121.ownerid = UserInfo.getUserId();
             SRS121.HexaBPM__Estimated_Hours__c = 10;
             insert SRS121;
           
        HexaBPM__Step__c St111 = new  HexaBPM__Step__c();
             st111.HexaBPM__Step_No__c =73.0;
             st111.HexaBPM__SR__c = SR11.id;
             st111.HexaBPM__Step_Template__c = ST31.id;
             st111.HexaBPM__Status__c = status11.id;
             st111.HexaBPM__SR_Step__c = SRS111.id;
             st111.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st111.HexaBPM__Step_Notes__c = 'test area';
             //sT111.OWNERID = '0053E000000HFrh';
             st111.ownerid = testGroup11.id;
             insert St111;
            // ST111.recordtypeid='0123E0000004JnP';
             //update st111;
//HexaBPM__SR__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!=null && stp.HexaBPM__SR__r.HexaBPM__Ultimate_SR_Menu_Text__c!='')            
             HexaBPM__Step__c St121 = new  HexaBPM__Step__c();
             st121.HexaBPM__Step_No__c =73.0;
             st121.HexaBPM__Due_Date__c=datetime.newInstance(2016, 9, 15, 9, 30, 0);
             st121.HexaBPM__Parent_Step__c = st111.id;
             //ST12.recordtype.developername = 'General';
             //ST121.recordtypeid='0123E0000004JnP';
             st121.HexaBPM__SR__c = SR11.id;
             st121.HexaBPM__Step_Template__c = ST31.id;
             st121.HexaBPM__Status__c = status11.id;
             st121.HexaBPM__SR_Step__c = SRS121.id;
             st121.HexaBPM__Sys_Step_Loop_No__c ='10.0_1';
             st121.HexaBPM__Step_Notes__c = 'test area';
             sT121.OWNERID = testGroup11.id;
             insert St121;
         
       
                     
        Contact con11 = new Contact();
         con11.AccountId = a1.Id;
         con11.email = 'test@gmail.com';
         con11.FirstName =  'Fname';
         con11.LastName = 'LName';
         insert con11;
       
       
        list<HexaBPM__Step__c> lstExistingSteps11 = new list<HexaBPM__Step__c>();
        lstExistingSteps11.add(St111);

        map<Id,string> mapStepTemplateQueues11 = new map<Id,string>();
        mapStepTemplateQueues11.put(testgroup11.id,'Test');
       
        map<Id,string> mapSRTemplateQueues11 = new map<Id,String>();
        mapSRTemplateQueues11.put(testgroup11.id,'Test');
       
            map<id,id> mapSROwner11= new map<id,id>();
            map<id,string> mapUserLicense11 = new map<id,string>();
           
            map<string,Id> mapStepRecType11 = new map<string,Id>();
            mapStepRecType11.put('General',recordTypeId);
           
            list<HexaBPM__SR_Steps__c> lstSRSteps11 = new list<HexaBPM__SR_Steps__c>();
            lstSRSteps11.add(SRS111);
           
     
   
 
         try{CC_Create_LoopTask LoopTask11 = new CC_Create_LoopTask();
      LoopTask11.GenerateLoopTask(lstExistingSteps11,mapStepQueues11,mapStepTemplateQueues11,mapSRStepQueues11,mapSRTemplateQueues11,
                                mapSROwner11,mapUserLicense11,mapStepRecType11,lstSRSteps11,Action11,St111);
                                          } catch(Exception e){}   
 
         
}
   
}