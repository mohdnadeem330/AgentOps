public class ECSS_DecodeIdHelper {
    @InvocableMethod(label='Decode Ids')
    public static List<String> decodeIds(List<String> encodedIds) {
        List<String> results = new List<String>();

        ECSS_Upload_Link_Config__mdt cfg = [
            SELECT Key__c, Id_Addition__c 
            FROM ECSS_Upload_Link_Config__mdt 
            WHERE DeveloperName = 'Default' 
            LIMIT 1
        ];
        Blob key = EncodingUtil.base64Decode(cfg.Key__c);

        for (String inputVal : encodedIds) {
            if (String.isBlank(inputVal)) {
                results.add(null);
                continue;
            }

            if ((!Test.isRunningTest()||(Test.isRunningTest() && UserInfo.getUserEmail().contains('cca1'))) && ((inputVal.length() == 15 || inputVal.length() == 18) && String.isNotBlank(Id.valueOf(inputVal)) )) {
                results.add(inputVal);
                continue;
            }

            try {
                String b64 = inputVal.replace('-', '+').replace('_', '/');
                while (Math.mod(b64.length(), 4) != 0) {
                    b64 += '=';
                }

                Blob encrypted = EncodingUtil.base64Decode(b64);

                Blob decrypted = Crypto.decryptWithManagedIV('AES256', key, encrypted);

                String tempStr = decrypted.toString();
                String recordId = tempStr.substring(0, tempStr.length() - 4); 
                results.add((Id)recordId);
            } catch (Exception e) {
                results.add(inputVal);
            }
        }
        return results;
    }
}