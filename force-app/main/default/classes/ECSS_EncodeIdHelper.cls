public class ECSS_EncodeIdHelper {
  /*  private static Blob getKey() {
        
       ECSS_Upload_Link_Config__mdt  cfg = [ SELECT Key__c, Id_Addition__c 
                                            FROM ECSS_Upload_Link_Config__mdt 
                                            WHERE DeveloperName = 'Default' 
                                            LIMIT 1];
		return EncodingUtil.base64Decode(cfg.Key__c);
    }*/
    @InvocableMethod(label='Encode Ids')
    public static List<String> encodeIds(List<String> recordIds) {
       /* List<String> results = new List<String>();
        for (String recordId : recordIds) {
            if (String.isNotBlank(recordId)) {
                String encoded = EncodingUtil.base64Encode(Blob.valueOf(recordId));
                
                encoded = encoded.replace('+','-').replace('/','_').replace('=','');
                results.add(encoded);
            } else {
                results.add(null);
            }
        }
        return results;*/
       // Blob key = getKey();
         ECSS_Upload_Link_Config__mdt  cfg = [ SELECT Key__c, Id_Addition__c 
                                            FROM ECSS_Upload_Link_Config__mdt 
                                            WHERE DeveloperName = 'Default' 
                                            LIMIT 1];
		Blob key = EncodingUtil.base64Decode(cfg.Key__c);
       List<String> results = new List<String>();
        for (String recordId : recordIds) {
            Blob data = Blob.valueOf((String)(recordId+''+cfg.Id_Addition__c));
            Blob encrypted = Crypto.encryptWithManagedIV('AES256', key, data);
            String b64 = EncodingUtil.base64Encode(encrypted);

            // Make URL-safe
            b64 = b64.replace('+','-').replace('/','_').replace('=','');
			results.add(b64);
            
        }
        return results;
        
    }
    
   
   
}