/***
Class     : DMCasePdfHandler
Author      : Smaartt
Description : This class is a controller for the DM_NOC_Pdf and DM_PermitToWork_pdf vf pages
TestClass   : DMCasePdfHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
****************************************************************************************************************/
public without sharing class DMCasePdfHandler {
    
    public Case caseRecord { get; private set; }
    public String pmcInfo { get;  set; }
    public String text1 { get;  set; }
    public String text2 { get;  set; }
    public Integer currentYear { get;  set; }
    public DMCasePdfHandler() {
        text1 ='CMO';
        text2 ='Community Management Office - CMO';
        currentYear = Date.today().year();
        // Retrieve the Case record
        caseRecord = [SELECT Id, CaseNumber,Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState,  NOC_Validity__c,
                      Account.BillingPostalCode,Account.BillingCountry,Account.P_O_Box__c,Account.Fax, Account.MobileNumber1__c, Project_Name__c, Request_Type__c, Service_Type__c,
                      Project_Consultant__c,CreatedDate,Sector_and_Plot_No__c,Appointed_Contractor__c,Permit_Type__c,Development_Name__c,
                      Purpose_of_Work__c,Scope_of_Work_Description_Location__c,Duration_of_Work_Days__c,Hazards_Identified_Environmental_Impact__c,Safety_Precautions_and_Controls_in_Place__c,Type_of_Hazard_and_Risk_Impact__c,Safety_Precautions_taken__c, 
                      Method_of_Excavation__c,Description, List_of_Equipment_to_be_Used_If_Any__c,Designation__c,Stakeholder_Reference_No__c,PMC_Reference_No__c,PMC_Approved_Date__c,NOC_to_be_Addressed_to__c,Description_By_Aldar__c,
                      Duration_of_Work_Months__c,Duration_of_Work_Years__c,Start_Date__c,End_Date__c,Location__c,Type,Product.Name,
                      CreatedBy.Email,CreatedBy.Name,CreatedBy.MobilePhone,TLA_Duration__c,Utility__c,Contact.MobilePhone__c
                      FROM Case
                      WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
         if(caseRecord!=null){
             if(caseRecord.Development_Name__c =='Saadiyat Island'){
                 text1='SMO';
                 text2='Saadiyat Management Office - SMO';
             }
            List<DM_Security_Emails_Config__mdt> pmcInfoRecords  = [SELECT PMC_Info__c FROM DM_Security_Emails_Config__mdt WHERE Type__c = :caseRecord.Type AND Development_Name__c = :caseRecord.Development_Name__c];
            if(pmcInfoRecords.size()>0){
                pmcInfo = pmcInfoRecords[0].PMC_Info__c;
            }
        }
        
    }
    
    
    
}