@RestResource( urlmapping='/docusign/publish/*' )
global class DocuSign_WebHookSubscription {
    
	@Httppost
    global static void handleNotification( ){
        try{
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;

            System.debug( 'Print request body >>>>>\n'+ req.requestBody );
            System.debug( 'Print request body to String >>>>>\n'+ req.requestBody.toString( ) );
            
            String jsonBody = req.requestBody.toString( );
            Map<String, Object> jsonBodyMap = ( Map<String, Object> ) JSON.deserializeUntyped( jsonBody );
			// System.debug( 'jsonBodyMap'+ jsonBodyMap );

            // if( !jsonBodyMap.containsKey( 'data' ) ) return null;
            Map<String, Object> dataMap = ( Map<String, Object> ) jsonBodyMap.get( 'data' );
            
            // if( !dataMap.containsKey( 'envelopeId' ) || !dataMap.containsKey( 'envelopeSummary' ) ) return null;
            String envelopeId = String.valueOf( dataMap.get( 'envelopeId' ) );
            Map<String, Object> envelopeSummaryMap = ( Map<String, Object> ) dataMap.get( 'envelopeSummary' );

            // if( !envelopeSummaryMap.containsKey( 'recipients' ) ) return null;
            String envelopeStatus = String.valueOf( envelopeSummaryMap.get( 'status' ) );
            Map<String, Object> recipientsMap = ( Map<String, Object> ) envelopeSummaryMap.get( 'recipients' );

            // if( !recipientsMap.containsKey( 'signers' ) ) return null;
            List<Object> signersList = ( List<Object> ) recipientsMap.get( 'signers' );
            System.debug(signersList.size() +'\n'+ String.join(signersList, '\n'));
            Map<String, String> signerKeyToStatusMap = new Map<String, String>( );
            for( Integer s=0; s < signersList.size( ); s++ ){
                Map<String, Object> signerMap = ( Map<String, Object> ) signersList[s];
                if( String.valueOf( signerMap.get( 'recipientType' ) ) == 'signer' ){
                    signerKeyToStatusMap.put( 
                        String.valueOf( signerMap.get( 'routingOrder' )  ) + '_' + String.valueOf( signerMap.get( 'email' )  ), 
                        String.valueOf( signerMap.get( 'status' ) ) 
                    );
                }
            }
            
            // System.debug(signerKeyToStatusMap);
            // TLA Start - Modified By Aswathi@smaartt and Sadhana@smaartt for R3 16/10/2024
            if(envelopeId != null){
                set<id> caseIds = new Set<id>();
                for(dfsle__Envelope__c env :[SELECT Id,dfsle__DocuSignId__c,dfsle__SourceId__c FROM dfsle__Envelope__c WHERE dfsle__SourceId__c!=null AND dfsle__SourceId__c LIKE '500%' AND dfsle__DocuSignId__c =:envelopeId]){
                    if(Schema.Case.getSObjectType() == ((Id)env.dfsle__SourceId__c).getSObjectType()){
                        caseIds.add(env.dfsle__SourceId__c);
                    }
                }
                if(caseIds.size()>0){
                    list<Document__c> docTobeUpdated = new list<Document__c>();
                    Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.DM_TLACaseRecordType).getRecordTypeId();
                    for(Document__c doc :[SELECT Id FROM Document__c WHERE Case__c = :caseIds AND (DocumentType__c = :Label.DM_DocumentTypeSignedCAS or DocumentType__c=:Label.DM_DocumentTypeFinalTLA) AND Case__r.RecordTypeId = :caseRecordTypeId]){
                        doc.DocuSignEnvelopeID__c=envelopeId;
                        docTobeUpdated.add(doc);
                    }
                    if(docTobeUpdated.size()>0){
                        Update docTobeUpdated;
                    }
                }
            }
            // TLA Finish

            if( !signerKeyToStatusMap.isEmpty() ){
                for( dfsle__EnvelopeStatus__c env : [
                    SELECT Id, dfsle__DocuSignId__c, dfsle__SourceId__c, dfsle__Completed__c, dfsle__Status__c, 
                        ( SELECT Id, dfsle__Email__c, dfsle__RoutingOrder__c, dfsle__Status__c
                          FROM dfsle__Recipients__r 
                          WHERE dfsle__Type__c = 'Signer' AND dfsle__Status__c != 'Completed' )
                    FROM dfsle__EnvelopeStatus__c 
                    WHERE dfsle__DocuSignId__c =: envelopeId AND dfsle__Status__c != 'Completed'
                        AND CreatedFromAPI__c = true] 
                ){
                    if( env.dfsle__Recipients__r != null && env.dfsle__Recipients__r.size() > 0 ){
                        List<dfsle__RecipientStatus__c> recipientsToUpdate = new List<dfsle__RecipientStatus__c>();
                        for( dfsle__RecipientStatus__c recipient: env.dfsle__Recipients__r ){
                            String key = recipient.dfsle__RoutingOrder__c + '_' + recipient.dfsle__Email__c;
                            if( signerKeyToStatusMap.containsKey( key ) ){
                                String newStatus = signerKeyToStatusMap.get( key );
                                if( !recipient.dfsle__Status__c.equalsIgnoreCase( newStatus ) ){
                                    recipient.dfsle__Status__c = statusMapping.containsKey( newStatus ) ? statusMapping.get( newStatus ) : newStatus;
                                    recipientsToUpdate.add( recipient );
                                }
                            }
                        }
                        // System.debug( 'To Update Recipients : ' + recipientsToUpdate.size() + '\n' + String.join(recipientsToUpdate, '\n') );
                        if(!recipientsToUpdate.isEmpty()){
                            update recipientsToUpdate;
                        }
                    }
                    if( !env.dfsle__Status__c.equalsIgnoreCase( envelopeStatus ) ){
                        env.dfsle__Status__c = statusMapping.containsKey( envelopeStatus ) ? statusMapping.get( envelopeStatus ) : envelopeStatus;
                        // System.debug('To Update Envelope : '+ env);
                        update env;
                    }
                }
            }

            res.responseBody = Blob.valueOf( '{success:true, event:"Push"}' );
            res.statusCode = 200;

        }catch( Exception e ){
            System.debug( 'Exception message '+ e.getMessage( ) );
        }
    }

    @HttpGet
    global static String doGet( ) {
        return '{"message":"Hello from DocuSign Webhook Service!!"}';
    }

    private final static Map<String, String> statusMapping = new Map<String, String>{ 'completed' => 'Completed', 'sent' => 'Sent' };
}