public class ECSS_Invocable_GetObjectName {
    
    @InvocableMethod
    public static List<Output> getOabjectName (List<Input> inputList) {
        List<Output> retList = new List<Output>();
        for(Input currInput : inputList){
            String recordId = currInput.Record;
            if (String.isBlank(recordId) || recordId.length() < 3) {
            }
            else{
                
                // Extract the 3-character prefix from the record ID
                String prefix = recordId.substring(0, 3);
                
                // Use the getGlobalDescribe method to find the object name by prefix
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                
                for (String objectName : globalDescribe.keySet()) {
                    // Check if the object prefix matches the record ID prefix
                    if (globalDescribe.get(objectName).getDescribe().getKeyPrefix() == prefix) {
                        Output currOut = new Output();
                        currOut.RecordName = objectName;
                        retList.add(currOut);
                    }
                    
                }
            }
            
        }
        return retList;
    }
    public class Input {
        @InvocableVariable(label='Record' required=false)
        public String Record;
    }
    public class Output {
        @InvocableVariable(label='RecordName' required=false)
        public String RecordName;
    }
}