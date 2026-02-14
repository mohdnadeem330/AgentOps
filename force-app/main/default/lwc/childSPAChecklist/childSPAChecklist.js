import { LightningElement,api,track,wire} from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import VALIDATED_BY_ADMIN_FIELD from '@salesforce/schema/SPAChecklist__c.ValidatedbySalesAdmin__c';
import VALIDATED_BY_CM_FIELD from '@salesforce/schema/SPAChecklist__c.ValidatedbyCMTeam__c';
import SPA_OBJECT from '@salesforce/schema/SPAChecklist__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi'; 
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';

export default class ChildSPAChecklist extends LightningElement {

    @api categoryName;
    @api allvalues;
    @track cValues=[];
    prfName;

    get disableCMInput(){
        return (this.prfName != 'Customer Management');
    }

    get disableSAInput(){
        return (this.prfName != 'Sales Admin');
    }

   get categoryValues(){
        if(this.allvalues.hasOwnProperty(this.categoryName)){
            this.cValues=JSON.parse(JSON.stringify(this.allvalues[this.categoryName]));
            return   this.cValues;
        } 

        return [];    
    }
    @wire(getRecord, {recordId: strUserId,fields: [PROFILE_NAME_FIELD] }) 
    wireuser({error,data}) {
        if (error) {
            this.error = error ; 
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value;        
        }
    }

    handleChange(event){

        var index= event.target.dataset.index;
        var idx= event.target.dataset.idx;
        var apiname= event.target.dataset.fieldApi;

        var targetval=event.target.value;
        this.cValues[index][apiname]=targetval;
      

    

    const selectedEvent = new CustomEvent("valchange", {
        detail: {
            'index':idx,
            'apiname':apiname,
            'value':targetval
        }
    });
    this.dispatchEvent(selectedEvent);
    }

    @track AdminOptions;
    @wire(getObjectInfo, { objectApiName: SPA_OBJECT })
    AdminInfo;
   
   
   @wire(getPicklistValues,
      {
          recordTypeId: '$AdminInfo.data.defaultRecordTypeId',
          fieldApiName: VALIDATED_BY_ADMIN_FIELD
        
      }
   )
   Adminval({error,data}){
      if(data){
          this.AdminOptions=data.values;
      }
   }
   
   @track CMOptions;
   @wire(getObjectInfo, { objectApiName: SPA_OBJECT })
   CMInfo;
   
   
   @wire(getPicklistValues,
     {
         recordTypeId: '$CMInfo.data.defaultRecordTypeId',
         fieldApiName: VALIDATED_BY_CM_FIELD
       
     }
   )
   CMval({error,data}){
     if(data){
         this.CMOptions=data.values;
     }
   }
   


}