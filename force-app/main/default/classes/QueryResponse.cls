global with sharing virtual class QueryResponse {
    
    public Integer count {get; private set;}
    public String objectName {get;set;}
    public List<Object> records {
        get;
        set {
            records = value;
            if (records!= null) this.count = records.size();
        }
    }
    
    global QueryResponse() {

        this.objectName = '';
        this.records = new List<Map<String, Object>>();
    }
    
    global QueryResponse (List<SObject> records, String objectName, Boolean processRecords) {
                
        this();
        
        this.objectName = objectName;
        
        if (records != null) {
        
            this.count = records.size();
            
            //---- Get only modified records
            if (processRecords) {  
                
                for (SObject obj : records) {
                    Map<String, Object> recordMap = obj.getPopulatedFieldsAsMap();
                    Map<String, Object> modifiedRecord = new Map<String, Object>(recordMap);
                    this.mapFunction(obj, modifiedRecord);
                    this.records.add(modifiedRecord);
                }
            }
            //---- Get all records
            else {
                this.records = records;
            }
        }
    }
    
    global QueryResponse (List<Map<String, Object>> records, String objectName) {
                
        this();
        this.objectName = objectName;
        this.records = records;
    }

    global QueryResponse (List<Object> records, String objectName) {
                
        this();
        this.objectName = objectName;
        this.records = records;
    }
    
    public virtual void mapFunction(Object obj, Map<String, Object> recordMap) {
       //Override 
    }
}