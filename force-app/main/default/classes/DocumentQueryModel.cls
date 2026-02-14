public class DocumentQueryModel {
    
    public String type              {get;set;}
    public String id                {get;set;}
    public Boolean isUploaded       {get;set;}
    public String documentURL       {get;set;}
    public String fileExtension     {get;set;}
    public Blob fileData            {get;set;}
    public String title             {get;set;}
    public Boolean isUploadable     {get;set;}
    public Boolean eligibleForeSign {get;set;}
    public String contentVersionId  {get;set;}
    public String signDocumentId    {get;set;}
    public Boolean isSignCompleted  {get;set;}
    public String documentCategory  {get;set;}
    public String unitName          {get;set;}
    public Boolean isDownloadable   {get;set;}
    public Datetime createdDate     {get;set;}
    public Date expiryDate          {get;set;}
    
    public DocumentQueryModel(Document__c document) {
        
        this.type = document.DocumentType__c;
        this.id = document.Id;
        this.isUploaded = true;
        this.documentURL = '';
        this.fileExtension = '';
        this.fileData = null;
        this.title = '';
        this.isUploadable = false;
        this.isDownloadable = false;
        this.isSignCompleted = false;
        
        String isUploadableDocument = System.Label.Uploadable_Documents;
        List<String> documentSet = isUploadableDocument.split(';');
        for(String documentType : documentSet)
        {
            if(document.DocumentType__c !=null && document.DocumentType__c.contains(documentType))
            {
                this.isUploadable = true;
            }                
//            this.isDownloadable = document.isDownloadable__c;
        }
        /*if(document.DocumentType__c !=null && document.DocumentType__c.contains('Signed') || document.DocumentType__c.contains('Other') || document.DocumentType__c.contains('National ID'))
            this.isUploadable = true;
        else 
            this.isUploadable = false;*/
        if(document.EligibleForeSign__c !=null && document.EligibleForeSign__c)
            this.eligibleForeSign = true;
        else 
            this.eligibleForeSign = false;
    }
    
    public DocumentQueryModel() {
        this.type = '';
        this.id = '';
        this.isUploaded = false;
        this.documentURL = '';
        this.fileExtension = '';
        this.fileData = null;
        this.title = '';
        this.isUploaded = false;
        this.eligibleForeSign = false;
        this.isSignCompleted = false;
    }
    
    public DocumentQueryModel(String fileExtension, Blob fileContent, String fileTitle) {
        this.fileExtension = fileExtension;
        this.fileData = fileContent;
        this.title = fileTitle;
    }

    public DocumentQueryModel(HexaBPM__SR_Doc__c document) {
        
        this.type = document.Name;
        this.id = document.Id;
        this.isUploaded = false;
        this.documentURL = '';
        this.fileExtension = '';
        this.fileData = null;
        this.title = '';
        this.isUploadable = false;
        this.eligibleForeSign = false;
        this.isSignCompleted = false;
    }
    //CONSTRUCTOR Created to return the external file details
    public DocumentQueryModel( External_Files__c  ext) {
        this.type = ext.File_Name__c;
        this.id = ext.Id;
        this.isUploaded = true;
        this.documentURL = ext.External_URL__c;
        this.fileExtension = ext.File_Format__c;
        this.fileData = null;
        this.title = ext.Comment__c;
        this.isUploadable = false;
        this.eligibleForeSign = false;
        this.isSignCompleted = false;
    }
    
    public DocumentQueryModel(String URL) {
        
    }
    
}