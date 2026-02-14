import { LightningElement, api, wire, track } from 'lwc';

    const FIELDS = [
        'Case.Id',
        'Case.Status',
        'Case.RecordTypeId',
        'Case.Sub_Status__c',
        'Case.Previous_Status__c',
        'Case.Previous_SubStatus__c'
    ];


    export default class CasePathLWC extends LightningElement {

        @api recordId
        @api recordTypeName
        //@track selectedValue; //used
        @api selectedValue;
        @track prevstatusVal //used
        @api prevSubstatusVal //used
        @track RecordTypeIdval
        @track showbutton =  false;
        @api picklistResolvedValues //pass resolved picklist from parent
        ResolvedValue
        @track isModalOpen = false
        @api record // pass Record from parent
        @api picklistFieldValues // pass status picklist from parent
            
        connectedCallback(){
        
        }

        get picklistValues() {
            let itemsList = [];
            // console.log(JSON.stringify(this.record));
            if (this.record.data) {
                if(this.record.data.fields.RecordTypeId.value)
                    {
                        this.RecordTypeIdval = this.record.data.fields.RecordTypeId.value;
                    // console.log('RecordTypeIdval' + this.RecordTypeIdval)
                    }
                if(this.record.data.fields.Previous_Status__c.value)
                    {
                        this.prevstatusVal = this.record.data.fields.Previous_Status__c.value;
                    //  console.log('Previous_Status__c' + this.prevstatusVal)
                    }
                if(this.record.data.fields.Previous_SubStatus__c.value)
                    {
                        this.prevSubstatusVal = this.record.data.fields.Previous_SubStatus__c.value;
                        //console.log('prevSubstatusVal' + this.prevSubstatusVal)
                    }

                this.showbutton = this.recordTypeName !== 'Third Party Payment NOC';
                if (!this.selectedValue && this.record.data.fields.Status.value) {
                    this.selectedValue = this.record.data.fields.Status.value + '';
                }
                if (this.picklistFieldValues && this.picklistFieldValues.data && this.picklistFieldValues.data.values) {
                
                    let selectedUpTo = 0;
                    for (let item in this.picklistFieldValues.data.values) {

                        if (Object.prototype.hasOwnProperty.call(this.picklistFieldValues.data.values, item)) {
                            let classList;
                            if (this.picklistFieldValues.data.values[item].value === this.selectedValue &&
                                this.selectedValue === 'Closed') {
                                classList = 'slds-path__item slds-is-complete';                            
                            }
                            else if (this.picklistFieldValues.data.values[item].value === this.selectedValue &&
                                this.selectedValue === 'Escalated') {
                                classList = 'slds-path__item slds-is-lost';                            
                            }
                            else if (this.picklistFieldValues.data.values[item].value === this.selectedValue) {
                                // classList = 'slds-path__item slds-is-current slds-is-active';
                                classList = 'slds-path__item slds-is-active';
                                selectedUpTo++;
                            }                        
                            else if (this.picklistFieldValues.data.values[item].value === this.prevstatusVal) {
                                classList = 'slds-path__item slds-is-current';                            
                            }
                            
                            else {
                                classList = 'slds-path__item slds-is-incomplete';
                            }

                        //  console.log(classList);

                            itemsList.push({
                                pItem: this.picklistFieldValues.data.values[item],
                                classList: classList
                            })
                        }
                    }
                    // console.log('selectedStatusValue = ' + this.selectedValue);
                    return itemsList;
                }
                }
            
            return null;
        }

        handleSelect(event) {
            console.log('Value', event.currentTarget.dataset.value);
            console.log('Prev Status', this.selectedValue);
            this.selectedValue = event.currentTarget.dataset.value;
        }

        handleMarkAsSelected() {

         if(this.selectedValue == 'Closed' && this.ResolvedValue == null)
                {
                    this.isModalOpen = true;
                    return;
                } 
          
            const fields = {};
            fields.Id = this.recordId;
            fields.Status = this.selectedValue;
            if(this.ResolvedValue != null)
            {
            fields.Resolved_Status__c = this.ResolvedValue;}

            const recordInput = { fields };

            console.log('child update called')
            const event = new CustomEvent('updaterecord', { detail: recordInput });
            this.dispatchEvent(event);
                    
        }


        closeModal() {
            this.isModalOpen = false;
        }

        handleChange(event) {
            this.ResolvedValue = event.detail.value;
        }

        handleSave() {
            this.closeModal();
            // if(this.ResolvedValue!= null)
            //    {
            this.handleMarkAsSelected();}
        //}
    }