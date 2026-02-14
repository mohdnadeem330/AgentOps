public class RETL_ContactYardiWrapper {

    /* ======================================================
         CONTACT WRAPPER
       ====================================================== */
    public class YardiContactWrapper {
        public List<YardiContact> Contacts;

        public void normalize() {
            if (Contacts != null) {
                for (YardiContact yc : Contacts) {
                    yc.normalize();
                }
            }
        }
    }

    public class YardiContact {
        public String Last_Name;
        public String SF_Ref_Contact_Id;
        public String Yardi_Contact_Code;
        public String First_Name;
        public String Salutation;
        public String Company_Name;
        public String Description;
        public String Title;
        public String URL;
        public String Contact_Date;
        public String Address_1;
        public String Address_2;
        public String Address_3;
        public String City;
        public String State;
        public String Zip_Code;
        public String Country;
        public String PhoneNumber_1;
        public String PhoneNumber_2;
        public String PhoneNumber_3;
        public String PhoneNumber_4;
        public String Email;
        public String Contact_Notes;

        public void normalize() {
            Last_Name = Last_Name == null ? '' : Last_Name;
            SF_Ref_Contact_Id = SF_Ref_Contact_Id == null ? '' : SF_Ref_Contact_Id;
            Yardi_Contact_Code = Yardi_Contact_Code == null ? '' : Yardi_Contact_Code;
            First_Name = First_Name == null ? '' : First_Name;
            Salutation = Salutation == null ? '' : Salutation;
            Company_Name = Company_Name == null ? '' : Company_Name;
            Description = Description == null ? '' : Description;
            Title = Title == null ? '' : Title;
            URL = URL == null ? '' : URL;
            Contact_Date = Contact_Date == null ? '' : Contact_Date;
            Address_1 = Address_1 == null ? '' : Address_1;
            Address_2 = Address_2 == null ? '' : Address_2;
            Address_3 = Address_3 == null ? '' : Address_3;
            City = City == null ? '' : City;
            State = State == null ? '' : State;
            Zip_Code = Zip_Code == null ? '' : Zip_Code;
            Country = Country == null ? '' : Country;
            PhoneNumber_1 = PhoneNumber_1 == null ? '' : PhoneNumber_1;
            PhoneNumber_2 = PhoneNumber_2 == null ? '' : PhoneNumber_2;
            PhoneNumber_3 = PhoneNumber_3 == null ? '' : PhoneNumber_3;
            PhoneNumber_4 = PhoneNumber_4 == null ? '' : PhoneNumber_4;
            Email = Email == null ? '' : Email;
            Contact_Notes = Contact_Notes == null ? '' : Contact_Notes;
        }
    }

    /* ======================================================
         ASSOCIATION WRAPPER
       ====================================================== */
    public class YardiAssociationWrapper {
        public List<YardiContactAssociation> ContactAssociation;
    }

    public class YardiContactAssociation {
        public String Role_Description;
        public String Record_code;
        public String Is_Primary;
        public String Object_Type;
        public String Yardi_Contact_Code;
        public String SF_Ref_Contact_Id;
        public String PrimaryLeasingAgent;
    }

    /* ======================================================
         RESPONSE WRAPPERS
       ====================================================== */
    public class YardiContactResponseWrapper {
        public String Yardi_Contact_Code;        
    }

    public class YardiContactAssociationResponse {
        public String SF_ContactAssociation_Id;
        public String Yardi_Contact_Code;
        public String Y_ContactAssociation_Id;
        public String Status;
        public String ErrorMessage;
    }
}