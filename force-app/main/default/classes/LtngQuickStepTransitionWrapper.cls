/******************************************************************************************
 *  Company     : Pwc
 *  Date        : 10/04/2020
 *  Description : Wrapper of QuickStep Transition

*******************************************************************************************/
public class LtngQuickStepTransitionWrapper {
    @AuraEnabled
    public FormFieldSection objFormSection{get;set;}
    
    @AuraEnabled
    public List<TransitionWrapper> ltngLstTrnsWrap{get;set;}
    @AuraEnabled
    public Boolean hasAccess {get; set;}
    @AuraEnabled
    public Integer listSize {get; set;}
    @AuraEnabled
    public String caseOfficerId {get; set;}
    @AuraEnabled
    public String caseOfficerName {get; set;}
    @AuraEnabled
    public String selectTransition {get; set;}
    @AuraEnabled
    public String rejectReason {get; set;}
    @AuraEnabled
    public String stepNotes {get; set;}
    @AuraEnabled
    public HexaBPM__Step__c step_ltng {get; set;}
    @AuraEnabled
    public map<id,HexaBPM__Step_Transition__c> ltngMapStepTransition {get;set;}
    @AuraEnabled
    public string SRId {get; set;}
    @AuraEnabled
    public string SRRequestType {get; set;}
    @AuraEnabled
    public string SRNumber {get; set;}
    @AuraEnabled
    public string flsErrorMessage {get; set;}
    @AuraEnabled
    public boolean flsErrorCheck {get; set;}
    @AuraEnabled
    public boolean isStepOwnedByQueue {get;set;}
    @AuraEnabled
    public string userType {get; set;}
    @AuraEnabled
    public string priceItemId {get; set;}
    @AuraEnabled
    public string payeeType {get; set;}
    @AuraEnabled
    public string pageURL {get; set;}
    @AuraEnabled
    public string errorMessage {get; set;}
    @AuraEnabled
    public boolean isError {get; set;}
    @AuraEnabled
    public boolean showReviewCommentsButton{get; set;}
    @AuraEnabled
    public string reviewCommentsUrl{get; set;}
    @AuraEnabled
    public string reviewApplicationLabel{get; set;}
    @AuraEnabled
    public string rawSOQLACO{get; set;}
    @AuraEnabled
    public string rawSOQL{get; set;}
    @AuraEnabled
    public string rawQueueSOQL{get; set;}
    @AuraEnabled
    public string lookUpLabel{get; set;}
    @AuraEnabled
    public Boolean NOT_PDFDocument{get; set;}
    
    @AuraEnabled
    public boolean showSourceOfPayment{get; set;}
    @AuraEnabled
    public boolean showFinanceTeamComments{get; set;}
    @AuraEnabled
    public String contactPersonEmail{get; set;}
    @AuraEnabled
    public Boolean showContactPersonEmail{get; set;}
    @AuraEnabled
    public object debugger;
    @AuraEnabled
    public String requestLeadSupervisor{get; set;}
    @AuraEnabled
    public String requestLeadSupervisorName{get; set;}

    @AuraEnabled 
    public Map<String, String> availableValues {get; set;}
    
    @AuraEnabled
    public Boolean IsInvoiceReversal {get; set;}//SS_210623_ADDED_TO_SHOW_CUST_MESSAGE_ON_SCREEN
    
    public LtngQuickStepTransitionWrapper(){
        this.ltngLstTrnsWrap = new List<TransitionWrapper>();
        this.hasAccess = false;
        this.listSize=0;
        this.selectTransition = '';
        this.rejectReason = '';
        this.stepNotes = '';
        this.step_ltng = null;
        this.ltngMapStepTransition = null;
        this.SRId='';
        this.SRRequestType='';
        this.SRNumber='';
        this.flsErrorMessage='';
        this.flsErrorCheck=false;
        this.isStepOwnedByQueue = false;
        this.priceItemId = '';
        this.isError = false;
        this.showReviewCommentsButton = false;
        this.reviewCommentsUrl = '';
        this.rawSOQLACO = '';
        this.pageURL = '';
        this.showSourceOfPayment =false;
        this.showFinanceTeamComments =false;
        this.contactPersonEmail = '';
        this.showContactPersonEmail = false;
        this.NOT_PDFDocument = false;
        this.requestLeadSupervisor = '';
        this.requestLeadSupervisorName = '';
        this.reviewApplicationLabel = 'Review Application';
        objFormSection = new FormFieldSection();
    }
    
public class FormFieldSection{
    @AuraEnabled
    public string SectionName{get; set;}
    
    @AuraEnabled
    public list<FormObjectsWrapper> SectionObjects{get; set;}
    
    /*
    @AuraEnabled
    public list<FormFieldsWrapper> SectionFields{get; set;}
    */
    
    public FormFieldSection(){
        SectionObjects = new list<FormObjectsWrapper>();
    }
    
}

//release 1.1
public class FormObjectsWrapper{
    @AuraEnabled
    public string ObjectApi{get; set;}
    
    @AuraEnabled
    public string FormId{get; set;}
    
    @AuraEnabled
    public string sObjectId{get; set;}
    
    @AuraEnabled
    public list<FormFieldsWrapper> SectionFields{get; set;}

    @AuraEnabled
    public Map<String, String> objRequestMap = new Map<String, String>();
}

//release 1.1
public class FormFieldsWrapper{
    @AuraEnabled
    public string ObjectApi{get; set;}
    
    @AuraEnabled
    public string FieldApi{ get; set;}
    
    @AuraEnabled
    public string FieldType{get; set;}
    
    @AuraEnabled
    public Object FieldValue{get; set;}
    
    @AuraEnabled
    public Object LookupValue{get; set;}
    
    @AuraEnabled
    public boolean IsReadOnly{ get; set; }
    @AuraEnabled
    public boolean IsRequired{get; set; }

    @AuraEnabled public boolean isRendered = true;
    
    public FormFieldsWrapper() {
        IsReadOnly = false;
        IsRequired = false;
    }
}
}