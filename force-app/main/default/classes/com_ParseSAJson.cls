public with sharing class com_ParseSAJson {
    public class Input {
        @InvocableVariable(required=true)
        public String json;
    }
    public class Output {
        @InvocableVariable
        public List<ServiceAppointment> records;
    }

    @InvocableMethod(label='Parse ServiceAppointments JSON')
    public static List<Output> parse(List<Input> inputs) {
        List<Output> outs = new List<Output>();
        for (Input i : inputs) {
            List<ServiceAppointment> recs =
                (List<ServiceAppointment>) JSON.deserialize(i.json, List<ServiceAppointment>.class);
            Output o = new Output();
            o.records = recs;
            outs.add(o);
        }
        return outs;
    }
}