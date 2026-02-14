public class ProformaInvoiceController {
    
    @InvocableMethod(label='Get Sobject Type' description='returns type of object')
    public static List<String> getSObjectType(List<String> recordId){
        system.debug('recordId '+recordId);
        if(recordId != null && recordId.size() > 0){
            Id recId = Id.valueOf(recordId[0]);
            return   new List<String>{recId.getSObjectType().getDescribe().getName()};
                }else{
                    return   new List<String>();
                }
    }
    
}