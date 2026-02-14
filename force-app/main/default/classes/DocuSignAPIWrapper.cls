public class DocuSignAPIWrapper {
 
    /* Wrapper class */
    public class AuthenticationRequestModel {
        public String grant_type                    {get;set;}
        public String assertion                     {get;set;}

        public AuthenticationRequestModel(String grantType, String assertion) {
            this.grant_type = grantType;
            this.assertion = assertion;
        }
    }

    public class AuthenticationResponseModel {
        public String access_token                  {get;set;}
        public String token_type                    {get;set;}
        public Integer expires_in                   {get;set;}
        public String scope                         {get;set;}
    }

    public class KeyValueModel {
        public String uaepass;
        public String idnow;
    }

    public class EnvelopeRequestModel {
        public String emailSubject                  {get;set;}
        public String emailBlurb                  {get;set;}
        public List<DocumentModel> documents        {get;set;}
        public RecipientModel recipients            {get;set;}
        public String status{get;set;}
        public notifications notification{get;set;}
    }
    public class notifications{
        public Boolean useAccountDefaults{get;set;}
        public notifications(){
            this.useAccountDefaults = true;
        }
    }

    public class DocumentModel {
        public Blob documentBase64                  {get;set;}
        public String name                          {get;set;}
        public String fileExtension                 {get;set;}
        public String documentId                    {get;set;}

        public DocumentModel(ContentVersion cv) {
            System.debug('Chirag'+cv);
            this.documentBase64 = cv.VersionData;
            this.name = cv.Title;
            this.fileExtension = cv.FileExtension;
            this.documentId = '1';
        }
    }
    
     public class RecipientModel {
        public List<SignerModel> signers {get;set;}
        
        public RecipientModel(Id AccountId,String PersonEmail,String Name, String anchorString, String signProvider,String signerType,String NamePlaceholder, String DatePlaceholder,String Stamp) {
            List<SignerModel> signers = new List<SignerModel>();
            signers.add(new SignerModel(AccountId,PersonEmail,Name, anchorString, signProvider,signerType,NamePlaceholder,DatePlaceholder,Stamp));
            this.signers = signers;
        }
        
        public RecipientModel() {
            this.signers = new List<SignerModel>();
        }
    }

    public class SignerModel {
        public Id AccountId {get;set;}
        public String email                                                 {get;set;}
        public String name                                                  {get;set;}
        public String recipientId                                           {get;set;}
        public String routingOrder                                          {get;set;}
        public String clientUserId                                          {get;set;}
        public String signerType                                          {get;set;}
        public List<SignProviderModel> recipientSignatureProviders          {get;set;}
        public TabModel tabs                                                {get;set;}
        public String EmbeddedRecipientStartURL                             {get;set;}

        public SignerModel(Id AccountId,String PersonEmail,String Name, String anchorString, String signProvider,String signerType,String NamePlaceholder, String DatePlaceholder,String Stamp) {
            this.AccountId = AccountId;
            this.email = PersonEmail;
            this.name = Name;
            //this.clientUserId = Name + '_' + PersonEmail; 
            this.clientUserId = AccountId + '_' + PersonEmail;// Added by Tajinkumar
            this.recipientId = '1';
            this.routingOrder = '1';
            this.signerType = signerType;
            this.recipientSignatureProviders = new List<SignProviderModel>();
            if (String.isNotBlank(signProvider)){
                this.recipientSignatureProviders.add(new SignProviderModel(signProvider));
            }
            if(signerType =='Approver'){
                this.tabs = new TabModel(anchorString,'Approve');
            }else{
                this.tabs = new TabModel(anchorString,NamePlaceholder,DatePlaceholder,Stamp);
            }
        }
        public SignerModel(Id AccountId,String PersonEmail,String Name, String anchorString, String signProvider,String recipientId,String routingOrder,String signerType,String signat,String NamePlaceholder, String DatePlaceholder,String Stamp) {
            this.AccountId = AccountId;
            this.email = PersonEmail;
            this.name = Name;
            if(signat !='SIGN_AT_DOCUSIGN'){
            //this.clientUserId = Name + '_' + PersonEmail;
              this.clientUserId = AccountId + '_' + PersonEmail;// Added by Tajinkumar
            }
            this.recipientId = recipientId;
            this.routingOrder = routingOrder;
            this.signerType = 'Signer';
            this.recipientSignatureProviders = new List<SignProviderModel>();
            if (String.isNotBlank(signProvider)){
                this.recipientSignatureProviders.add(new SignProviderModel(signProvider));
            }
            if(signerType =='Approver'){
                this.tabs = new TabModel(anchorString,'Approve');
            }else{
                this.tabs = new TabModel(anchorString,NamePlaceholder,DatePlaceholder,Stamp);
            }
        }
    }

    public class SignProviderModel {
        public String signatureProviderName                                 {get;set;}
        public Map<String, String> signatureProviderOptions                 {get;set;}

        public SignProviderModel(String signProvider) {
            this.signatureProviderName = signProvider;
            this.signatureProviderOptions = new Map<String, String>();
        }
    }

    public class TabModel {
        public List<SignHereModel> signHereTabs     {get;set;}
        public List<ApproverModel> approveTabs     {get;set;}
        
        public List<dateSignedModal> dateSignedTabs     {get;set;}
        public List<fullNameModal> fullNameTabs     {get;set;}

        public TabModel(String anchorString,String Nameplaceholder, String DatePlaceholder,String Stamp ) {
            List<SignHereModel> signHereTabs = new List<SignHereModel>();
            signHereTabs.add(new SignHereModel(anchorString));
            if(Stamp =='Stamp'){
            signHereTabs.add(new SignHereModel('AldarStampHolder','stamp'));
            }

            List<dateSignedModal> dateSignedTabs = new List<dateSignedModal>();
            dateSignedTabs.add(new dateSignedModal(DatePlaceholder));
            this.dateSignedTabs = dateSignedTabs;
            List<fullNameModal> fullNameTabs = new List<fullNameModal>();
            fullNameTabs.add(new fullNameModal(Nameplaceholder));
            this.fullNameTabs = fullNameTabs;
            this.signHereTabs = signHereTabs;
            List<ApproverModel> approveTabs = new List<ApproverModel>();
            this.approveTabs = approveTabs;
        }
        public TabModel(String anchorString,String buttonText){
            List<SignHereModel> signHereTabs = new List<SignHereModel>();

            this.signHereTabs = signHereTabs;
            List<ApproverModel> approveTabs = new List<ApproverModel>();
            approveTabs.add(new ApproverModel(anchorString,buttonText));

            this.approveTabs = approveTabs;
           
        }
    }
    public class ApproverModel{
        public String buttonText {get;set;}
        public String anchorString {get;set;}
        public String documentId {get;set;}
        public String xPosition                 {get;set;}
        public String yPosition                 {get;set;}
        public String pageNumber {get;set;}
        public ApproverModel(String anchorString,String buttonText) {
            this.xPosition = '210';
            this.yPosition = '105';
            this.buttonText = buttonText;
            this.documentId = '1';
            this.pageNumber = '1';
        }
    }
    

    public class SignHereModel {
        public String anchorString                  {get;set;}
        public String anchorUnits                   {get;set;}
        public String xPosition                 {get;set;}
        public String yPosition                 {get;set;}
        public String pageNumber {get;set;}
        public String documentId {get;set;}
        public String stampType {get;set;}

        public SignHereModel(String anchorString) {
            this.anchorString = anchorString;
            this.anchorUnits = 'pixels';
            this.xPosition = '200';
            this.yPosition = '300';
            this.pageNumber = '1';
            this.documentId = '1';
        }
        public SignHereModel(String anchorString,String Stamp) {
            this.anchorString = anchorString;
            this.anchorUnits = 'pixels';
            this.xPosition = '200';
            this.yPosition = '300';
            this.pageNumber = '1';
            this.documentId = '1';
            this.stampType = 'stamp';
        }
       
    }

    public class InitialHereModel {
        public String anchorString                  {get;set;}
        public String anchorUnits                   {get;set;}
        public String xPosition                 {get;set;}
        public String yPosition                 {get;set;}
        public String pageNumber {get;set;}
        public String documentId {get;set;}

        public InitialHereModel(String anchorString) {
            this.anchorString = anchorString;
            this.anchorUnits = 'pixels';
            this.xPosition = '200';
            this.yPosition = '300';
            this.pageNumber = '1';
            this.documentId = '1';
        }
    }

    public class dateSignedModal {
        public String anchorString                  {get;set;}
        public String anchorUnits                   {get;set;}
        public String xPosition                 {get;set;}
        public String yPosition                 {get;set;}
        public String pageNumber {get;set;}
        public String documentId {get;set;}

        public dateSignedModal(String anchorString) {
            this.anchorString = anchorString;
            // this.anchorUnits = 'pixels';
            // this.xPosition = '200';
            // this.yPosition = '300';
            // this.pageNumber = '1';
            this.documentId = '1';
        }
    }
    public class fullNameModal {
        public String anchorString                  {get;set;}
        public String anchorUnits                   {get;set;}
        public String xPosition                 {get;set;}
        public String yPosition                 {get;set;}
        public String pageNumber {get;set;}
        public String documentId {get;set;}

        public fullNameModal(String anchorString) {
            this.anchorString = anchorString;
            // this.anchorUnits = 'pixels';
            // this.xPosition = '200';
            // this.yPosition = '300';
            // this.pageNumber = '1';
            this.documentId = '1';
        }
    }
    

    public class EnvelopeResponseModel {
        public String envelopeId                    {get;set;}
        public String uri                           {get;set;}
        public String statusDateTime                {get;set;}
        public String status                        {get;set;}
    }

    public class URLRequestModel {
        public String returnUrl                     {get;set;}
        public String authenticationMethod          {get;set;}
        public String email                         {get;set;}
        public String userName                      {get;set;}
        public String clientUserId                  {get;set;}

        public URLRequestModel(String returnUrl, Account acc) {
            this.returnUrl = returnUrl;
            this.authenticationMethod = 'none';
            this.email = acc.PersonEmail;
            this.userName = acc.Name;
            this.clientUserId = acc.Id + '_' + acc.PersonEmail;
        }
    }

    public class URLResponseModel {
        public String url                           {get;set;}
    }
}