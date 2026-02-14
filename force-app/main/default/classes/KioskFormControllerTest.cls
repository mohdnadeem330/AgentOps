/**********************************************************************************************************************
* Name               : KioskFormControllerTest                                                       
* Description        : Test class for KioskFormController and RecaptchaController.
* Usage              :                                                           
* Created By         : Muzammil                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Muzammil     		14 Mar 2022      Initial Draft       
******************************************************************************************************************/
@isTest
public class KioskFormControllerTest {
    
    @testSetup
    public static void createRecords(){
        AllocationGroup__c ag = new AllocationGroup__c(Name='DXB',ShowOnKiosk__c=true,StartDate__c=date.today(),EndDate__c=date.today().addDays(30), AllocationGroupCode__c='DXB1');
        Insert ag;
        AllocationGroupUser__c agu = new AllocationGroupUser__c(User__c=userInfo.getUserId(),AllocationGroup__c=ag.Id,StartDate__c=date.today(),EndDate__c=date.today().addDays(30));
        Insert agu;
        KioskPageCampaign__c campaign = new KioskPageCampaign__c(Name='TestCampaign',IsActive__c=true);
        Insert campaign;
        KioskPageSection__c section = new KioskPageSection__c(Name='Request Call Back',IsActive__c=true,Kiosk_Page_Campaign__c=campaign.Id,Kiosk_Page_Section_Order__c=1);
        Insert section;
        List<KioskPageField__c> fieldList = new List<KioskPageField__c>();
        KioskPageField__c field1 = new KioskPageField__c(Name='FirstName',Field_Type__c='Text',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='FirstName',Field_Order__c=1,SkipSave__c=false);
        fieldList.add(field1);
        KioskPageField__c field2 = new KioskPageField__c(Name='LastName',Field_Type__c='Text',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='LastName',Field_Order__c=1,SkipSave__c=false);
        fieldList.add(field2);
        KioskPageField__c field3 = new KioskPageField__c(Name='Project',Field_Type__c='Text',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='Project__c',Field_Order__c=1,SkipSave__c=false);
        fieldList.add(field3);
        KioskPageField__c field6 = new KioskPageField__c(Name='City',Controlling_FIeld__c='ResidentStatus__c',Controlling_Field_Value__c='Resident',Field_Type__c='Picklist',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='Emirate__c',Get_picklist_values_from_schema__c=true,Picklist_schema_name__c='Lead.Emirate__c',Field_Order__c=1,SkipSave__c=false);
        fieldList.add(field6);
        KioskPageField__c field4 = new KioskPageField__c(Name='unitType',Field_Type__c='Picklist',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='UnitType__c',Field_Order__c=1,SkipSave__c=false,Picklist_Values__c='Apartment=>Apartment;Bulk=>Bulk;Kiosk=>Kiosk;Land Plot=>Land Plot;Office=>Office;Pent House=>Pent House;Retail=>Retail;Town House=>Town House;Villa=>Villa');
        fieldList.add(field4);
        KioskPageField__c field5 = new KioskPageField__c(Name='CustomerBudget__c',Query_from_object__c=true,Field_Type__c='Picklist',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='CustomerBudget__c',Field_Order__c=1,SkipSave__c=false,Picklist_schema_name__c='Lead.CustomerBudget__c');
        fieldList.add(field5);
        KioskPageField__c field7 = new KioskPageField__c(Name='Nationality__c',Query_from_object__c=true,Field_Type__c='Picklist',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='Nationality__c',Field_Order__c=1,SkipSave__c=false,Picklist_schema_name__c='Lead.Nationality__c');
        fieldList.add(field7);
         KioskPageField__c field8 = new KioskPageField__c(Name='City',Field_Type__c='Picklist',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='Emirate__c',Get_picklist_values_from_schema__c=true,Picklist_schema_name__c='Lead.Emirate__c',Field_Order__c=1,SkipSave__c=false);
        fieldList.add(field8);
        Insert fieldList;
        List<KioskDefaultFields__c> defaultList = new List<KioskDefaultFields__c>();
        KioskDefaultFields__c defaultField1 = new KioskDefaultFields__c(Name='Method of Contact',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='LeadSource',DependentFieldValue__c='Walk-In');
        defaultList.add(defaultField1);
        KioskDefaultFields__c defaultField2 = new KioskDefaultFields__c(Name='EnquiryCategory',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='EnquiryCategory__c',DependentFieldValue__c='Aldar Show Home');
        defaultList.add(defaultField2);
        
        KioskDefaultFields__c defaultField3 = new KioskDefaultFields__c(Name='EnquiryTrigger',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='EnquiryTrigger__c',DependentFieldValue__c='Mayan Show Home');
        defaultList.add(defaultField3);
        KioskDefaultFields__c defaultField4 = new KioskDefaultFields__c(Name='LastName',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='LastName',DependentFieldValue__c='LastNameTest');
        defaultList.add(defaultField4);
        KioskDefaultFields__c defaultField5 = new KioskDefaultFields__c(Name='Project',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='Project__c',DependentFieldValue__c='Mayan');
        defaultList.add(defaultField5);
        KioskDefaultFields__c defaultField6 = new KioskDefaultFields__c(Name='PurposrOfUse',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='PropertyUsage__c',DependentFieldValue__c='Corporate');
        defaultList.add(defaultField6);
         KioskDefaultFields__c defaultField7 = new KioskDefaultFields__c(Name='SalesType',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='SalesType__c',DependentFieldValue__c='Institutional');
        defaultList.add(defaultField7);
        KioskDefaultFields__c defaultField8 = new KioskDefaultFields__c(Name='EnquiryCategoryDepe',ControllingField__c='EnquiryCategory__c',ControllingFieldValue__c='Aldar Show Home',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='ContactSource__c',DependentFieldCheckbox__c=true	,DependentFieldValue__c='Normal');
        defaultList.add(defaultField8);
        
         KioskDefaultFields__c defaultField9 = new KioskDefaultFields__c(Name='FirstName',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='FirstName',DependentFieldValue__c='FirstNameTest');
        defaultList.add(defaultField9);
        KioskDefaultFields__c defaultField10 = new KioskDefaultFields__c(Name='MobilePhone',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='MobilePhone',DependentFieldValue__c='0528843730');
        defaultList.add(defaultField10);
        KioskDefaultFields__c defaultField11 = new KioskDefaultFields__c(Name='OwnerId',KioskPageCampaign__c=campaign.Id,IsActive__c=true,DependentField__c='OwnerId',DependentFieldValue__c=userinfo.getUserId());
        defaultList.add(defaultField11);

        Insert defaultList;
        KioskDependentPicklistValue__c dependentValue1 = new KioskDependentPicklistValue__c(Name='No of Bedrooms',Controlling_Field_Value__c='Mayan',ControllingFieldText__c='Project__c',DependentFieldText__c='NumberOfBedrooms__c',DependentFieldValueTextArea__c='1BHK=>1BHK;1BHK + 1=>1BHK + 1;2BHK=>2BHK;2BHK +1=>2BHK +1;2BHK + M=>2BHK + M;3BHK=>3BHK;4BHK=>4BHK;5BHK=>5BHK;6BHK=>6BHK',isActive__c=true);
        Insert dependentValue1;
         KioskDependentPicklistValue__c dependentValue2 = new KioskDependentPicklistValue__c(Name='CustomerBudget__c',Controlling_Field_Value__c='Mayan',ControllingFieldText__c='Project__c',DependentFieldText__c='CustomerBudget__c',DependentFieldValueTextArea__c='300,000 - 499,000=>300,000 - 499,000;500,000 - 699,000=>500,000 - 699,000;700,000-999,000=>700,000-999,000;1 Million - 1.9 Million=>1 Million - 1.9 Million;2 Million - 2.9 Million=>2 Million - 2.9 Million;3 Million - 3.9 Million=>3 Million - 3.9 Million;4 Million - 4.9 Million=>4 Million - 4.9 Million;5 Million - 5.9 Million=>5 Million - 5.9 Million;6 Million and above=>6 Million and above',isActive__c=true);
        Insert dependentValue2;
        //g: [LastName, EnquiryCategory__c, EnquiryTrigger__c, Project__c]: [LastName, EnquiryCategory__c, EnquiryTrigger__c, Project__c]
        //        KioskPageField__c field1 = new KioskPageField__c(Name='FirstName',Field_Type__c='Text',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='EnquiryCategory__c',Field_Order__c=1,SkipSave__c=false);
        //        KioskPageField__c field1 = new KioskPageField__c(Name='FirstName',Field_Type__c='Text',IsActive__c=true,Object_API_Name__c='Lead',Required__c=true,Kiosk_Page_Section__c=section.Id,Field_API_Name__c='EnquiryTrigger__c',Field_Order__c=1,SkipSave__c=false);
        
    }
    
    @isTest
    public static void testMethod1(){
        List<KioskFormController.DisplaySectionWrapper> ds = new List<KioskFormController.DisplaySectionWrapper>();
        List<KioskPageSection__c> sectionList = new List<KioskPageSection__c>();
        sectionList = [SELECT Id,Kiosk_Page_Campaign__c,Kiosk_Page_Campaign__r.Name FROM KioskPageSection__c  LIMIT 1  ];
        if(sectionList.size() > 0){
            ds= KioskFormController.getInitData(sectionList[0].Kiosk_Page_Campaign__r.Name);
            for(KioskFormController.DisplaySectionWrapper a : ds){
                for(KioskFormController.DisplayFieldDataWrapper field : a.fieldData ){
                    system.debug('+++field '+field);
                    if(field.fieldApiName == 'LastName'){
                        field.value = 'Test11';
                    }if(field.fieldApiName == 'FirstName'){
                        field.value = 'Test11';
                    }
                    /*if( field.fieldApiName=='Project__c'){
                        field.value='Mayan';
                    }
                    if( field.fieldApiName=='UnitType__c'){
                        field.value='Apartment';
                    }
                  */
                    field.skipSave = false;
                }
                //   a.fielddata = 
                //   
            }
            system.debug('ds '+ds);
            List<Group> queueList = new List<Group>();
            queueList = [select Id,DeveloperName  from Group where Type = 'Queue' ];
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new RecaptchaControllerMockTest());
            KioskFormController.saveData(JSON.serialize(ds),'a',String.valueOf(sectionList[0].Id) ,String.valueOf(sectionList[0].Kiosk_Page_Campaign__c),queueList[0].DeveloperName);
            KioskFormController.cloneCampaign cloneCamp1 = new KioskFormController.cloneCampaign();
            cloneCamp1.cloneFromId = sectionList[0].Kiosk_Page_Campaign__c;
            cloneCamp1.campaignName = 'TestCamp';
            KioskFormController.cloneFromCampaign(new List<KioskFormController.cloneCampaign> {cloneCamp1} );
            test.stopTest();
        }
    }
    
   /*  @isTest
    public static void testMethod2(){
        List<KioskFormController.DisplaySectionWrapper> ds = new List<KioskFormController.DisplaySectionWrapper>();
        List<Kiosk_Page_Section__mdt> sectionList = new List<Kiosk_Page_Section__mdt>();
        sectionList = [SELECT Id,Kiosk_Page_Campaign__c,Kiosk_Page_Campaign__r.MasterLabel FROM Kiosk_Page_Section__mdt  LIMIT 1  ];
        if(sectionList.size() > 0){
            ds= KioskFormController.getInitData(sectionList[0].Kiosk_Page_Campaign__r.MasterLabel);
            List<Group> queueList = new List<Group>();
            queueList = [select Id,DeveloperName  from Group where Type = 'Queue' ];
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new RecaptchaControllerMockFailureTest());
            KioskFormController.saveData(JSON.serialize(ds),'a',String.valueOf(sectionList[0].Id) ,String.valueOf(sectionList[0].Kiosk_Page_Campaign__c),queueList[0].DeveloperName);
            test.stopTest();
        }
    }*/
}