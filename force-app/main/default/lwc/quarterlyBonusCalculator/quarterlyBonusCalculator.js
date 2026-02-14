import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import runQuarterlyPayout from '@salesforce/apex/QuarterlyBonusController.runQuarterlyPayout';
import BrokerPayoutType from '@salesforce/label/c.BrokerPayoutType';
import BrokerPayoutYear from '@salesforce/label/c.BrokerPayoutYear';

export default class QuarterlyBonusComponent extends LightningElement {
    @track selectedQuarter = null;
    @track selectedYear = null;
    @track selectedType = null;

    @track typeOptions = [];


    get showQuarterAndYear(){
        if(this.selectedType){
            return true;
        }
        return false;
    }

    quarterOptions = [
        { label: 'Q1', value: 'Q1' },
        { label: 'Q2', value: 'Q2' },
        { label: 'Q3', value: 'Q3' },
        { label: 'Q4', value: 'Q4' }
    ];

    @track yearOptions = [
        // { label: '2024', value: '2024' },
        // { label: '2025', value: '2025' },
        // { label: '2026', value: '2026' },
        // { label: '2027', value: '2027' },
        // { label: '2028', value: '2028' },
        // { label: '2029', value: '2029' }
    ];

    async connectedCallback(){
        var today = new Date();
var quarter = Math.floor((today.getMonth() + 3) / 3);

        this.yearOptions = [];
        let listPayoutYear = BrokerPayoutYear.split(',');

        if(listPayoutYear.length > 0){
            for(let i=0; i<listPayoutYear.length; i++){
                const objectData = {
                    label : listPayoutYear[i],
                    value : listPayoutYear[i]
                }   
                this.yearOptions.push(objectData);
            }
        }

        let listPayoutType = BrokerPayoutType.split(','); 
        this.typeOptions = [];

        if(listPayoutType.length > 0){
            for(let i=0; i<listPayoutType.length; i++){
                const objectData = {
                    label : listPayoutType[i],
                    value : listPayoutType[i]
                }   
                this.typeOptions.push(objectData);
            }
        }
    }

    handleTypeChange(event){
        this.selectedType = event.detail.value;
    }

    handleQuarterChange(event) {
        this.selectedQuarter = event.detail.value;
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
    }

    async calculateBonus() {
        if (!this.selectedQuarter || !this.selectedYear || !this.selectedType) {
            this.showErrorToast('Please select Type, Quarter and Year.');
            return;
        }

        try {
            // Call the Apex method with type, quarter and year as parameters
            await runQuarterlyPayout({ type : this.selectedType,  
                                      quarter: this.selectedQuarter, 
                                      year: this.selectedYear });

            this.showSuccessToast(`Your ${this.selectedType} Calculation Completed.`);
            this.resetSelections();
        } catch (error) {
            // Show error toast if there's an exception from the Apex method
            this.showErrorToast(error.body.message);
        }
    }

    resetSelections() {
        this.selectedQuarter = null;
        this.selectedYear = null;
        this.selectedType = null;
    }

    showSuccessToast(message) {
        this.showToast('Success', message, 'success');
    }

    showErrorToast(message) {
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}