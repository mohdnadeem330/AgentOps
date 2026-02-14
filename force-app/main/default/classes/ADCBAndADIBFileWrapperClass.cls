public class ADCBAndADIBFileWrapperClass {
    
    public cls_Data Data;

    public class cls_Data {
        public String RequestType;
        public String BankReference;
        public String OICCode;
        public String File;
        public String FileName;
    }
    public ADCBAndADIBFileWrapperClass(){
        this.data = new cls_Data();
    }
    public static ADCBAndADIBFileWrapperClass parse(String json){
        return (ADCBAndADIBFileWrapperClass) System.JSON.deserialize(json, ADCBAndADIBFileWrapperClass.class);
    }
}