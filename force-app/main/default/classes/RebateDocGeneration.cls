global class RebateDocGeneration implements  Queueable, Database.AllowsCallouts{ 
    
    public List<SalesOrder__c> SOIds;
    public String srId;
    public String triggerpoint;
    public RebateDocGeneration(List<SalesOrder__c> SOIdList, String Srequestid)
    {
    this.SOIds = SOIdList;
    this.srId = Srequestid;
    
    }
    public RebateDocGeneration(List<SalesOrder__c> SOIdList, String Srequestid, String triggerpt)
    {
    this.SOIds = SOIdList;
    this.srId = Srequestid;
    this.triggerpoint = triggerpt;
    }

    public void execute(QueueableContext context)
    {
    map<id,id> mapToReturn = new map<id,id>();

    String DocMasterCode = this.triggerpoint == 'Revised SOA' ? 'Revised_Statement_of_Account' : 'Statement of Account';
    HexaBPM__SR_Doc__c assRec = [Select Id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:srId AND  DocumentMasterCode__c= : DocMasterCode];
    List<map<id,ContentVersion >> ListofcontentVersionMap = new List<map<id,ContentVersion >>();

    for(SalesOrder__c tempRec : SOIds){
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        PageReference pdf = Page.StatementOfAccountDocument;
        pdf.getParameters().put('id',tempRec.id);
        contentVersionMap.put(assRec.Id, new ContentVersion(Title= 'StatementOfAccountDocument.pdf', 
                                                            PathOnClient ='StatementOfAccountDocument.pdf',
                                                            VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent(), 
                                                            origin = 'H'));
        ListofcontentVersionMap.add(contentVersionMap);
                                                        
    }
    if(!ListofcontentVersionMap.isEmpty())
    {
        list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
    for(map<id,ContentVersion> contentVersionMap: ListofcontentVersionMap){
        insert contentVersionMap.values();
        map<id,ContentVersion> cvMap = new  map<id,ContentVersion>([select id, ContentDocumentId  from ContentVersion where id in :contentVersionMap.values()]);
        
        for(Id docID : contentVersionMap.keySet()){
            mapToReturn.put(docID , cvMap.get(contentVersionMap.get(docID).Id).ContentDocumentId );
            documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = mapToReturn.get(docID),
                                                        LinkedEntityId = docID,
                                                        ShareType ='V'));

        }
        
    }
        system.debug('documentLinksToCreate' + documentLinksToCreate);
    insert documentLinksToCreate;
    }
    }
    }