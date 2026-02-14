global class FileUploadModel{

    public Id accountId              {get;set;}
    public String documentType       {get;set;}
    public Boolean isPersonAccount   {get;set;}
    public Blob fileData             {get;set;}
    public String fileTitle          {get;set;}
    public Id documentId             {get;set;}
    public Id contentVersionId       {get;set;}
    public String referenceId        {get;set;}
}