public class RETL_YardiCustomTableWrapper {

    // -----------------------------
    // Request Payload Classes
    // -----------------------------
    public class CustomTableRequest {
        public String Timestamp;
        public String Reserve1 = '';
        public String Reserve2 = '';
        public String Reserve3 = '';
        public String Reserve4 = '';
        public String Reserve5 = '';
        public String RequestId;
        public String Description;
        public List<TableWrapper> Details;
    }

    public class TableWrapper {
        public String TableName;
        public List<RecordWrapper> Data;
    }

    public class RecordWrapper {
        public String EntityRecordCode;
        public String CustomTableRecordCode;
        public List<FieldWrapper> Fields;
    }

    public class FieldWrapper {
        public String FieldName;
        public Object FieldValue;
        public FieldWrapper(String name, Object value) {
            this.FieldName = name;
            this.FieldValue = value;
        }
    }

    // -----------------------------
    // Response Payload Classes
    // -----------------------------
    public class CustomTableResponse {
        public String Status;
        public String Message;
        public String ResponseCode;
        public String Action;
        public String RequestId;
        public String Timestamp;
        public List<ResponseDetail> Details;
    }

    public class ResponseDetail {
        public String TableName;
        public String EntityRecordCode;
        public String ParentRecordCode;
        public String CustomTableRecordCode;
        public String Status;
        public String Message;
        public String ResponseCode;
    }

}