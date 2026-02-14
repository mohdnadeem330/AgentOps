import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getRelatedAccountNames from '@salesforce/apex/CreateShipmentRequestController.getRelatedAccountNames';
import saveShipmentRequest from '@salesforce/apex/CreateShipmentRequestController.saveShipmentRequest';

const COLUMNS = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Relationship Type', fieldName: 'relationshipType' }
];

export default class CreateShipmentRequest extends LightningElement {
    @track recId;
    @track columns = COLUMNS;
    @track jointOwners = [];
    @track joMap = {};
    @track accountOptions = [];
    @track accountValue = '';
    @track addressOptions = [
        { 'label': 'Permanent Address', 'value': 'BillingAddress' },
        { 'label': 'Residential Address', 'value': 'ShippingAddress' },
        { 'label': 'Other Address', 'value': 'OtherAddress' }
    ]
    @track addressValue = 'ShippingAddress';
    @track address = {};
    @track isLoading = false;

    async connectedCallback() {
        this.recId = new URL(window.location.href).searchParams.get("c__rId");
        
        this.isLoading = true;
        await getRelatedAccountNames({
            rId: this.recId
        }).then(result => {
            let tempResult = JSON.parse(JSON.stringify(result));
            this.jointOwners = [];
            this.accountOptions = [];
            this.joMap = {};
            if (tempResult) {
                for (let i = 0; i < result.length; i++) {
                    this.jointOwners.push({ id: result[i].Id, name: result[i].Name, relationshipType: result[i].RelationshipType });
                    this.accountOptions.push({ label: result[i].Name, value: result[i].Id });

                    let jo = {
                        BillingAddress: {
                            Name: result[i].Name,
                            Street: result[i].BillingStreet ? result[i].BillingStreet : '',
                            City: result[i].BillingCity ? result[i].BillingCity : '',
                            State: result[i].BillingState ? result[i].BillingState : '',
                            PostalCode: result[i].BillingPostalCode ? result[i].BillingPostalCode : '',
                            Country: result[i].BillingCountry ? result[i].BillingCountry : ''
                        },
                        ShippingAddress: {
                            Name: result[i].Name,
                            Street: result[i].ShippingStreet ? result[i].ShippingStreet : '',
                            City: result[i].ShippingCity ? result[i].ShippingCity : '',
                            State: result[i].ShippingState ? result[i].ShippingState : '',
                            PostalCode: result[i].ShippingPostalCode ? result[i].ShippingPostalCode : '',
                            Country: result[i].ShippingCountry ? result[i].ShippingCountry : ''
                        },
                        OtherAddress: {
                            Name: result[i].Name,
                            Street: '',
                            City: '',
                            State: '',
                            PostalCode: '',
                            Country: ''
                        }
                    }
                    this.joMap[result[i].Id] = jo;
                }
            }
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>', error);
            this.isLoading = false;
        });
    }

    handleChange(event) {
        if (event.target.name == 'Account') {
            this.accountValue = event.detail && event.detail.value ? event.detail.value : event.target.value;
        } else if (event.target.name == 'Address') {
            this.addressValue = event.detail && event.detail.value ? event.detail.value : event.target.value;
        }

        if (this.accountValue && this.accountValue != '' && this.addressValue && this.addressValue != '') {
            if (this.joMap.hasOwnProperty(this.accountValue)) {
                this.address = this.joMap[this.accountValue][this.addressValue];
                console.log('address>>>', JSON.stringify(this.address));
            }
        }
    }

    handleAddressChange(event) {
        this.address[event.target.name] = event.detail && event.detail.value ? event.detail.value : event.target.value;
    }

    async handleSave(event) {
        console.log('address>>>', JSON.stringify(this.address));
        let isError = false;
        let errorFields = ''
        if (!this.accountValue) {
            errorFields = 'Account';
            isError = true;
        }
        if (!this.address.Street) {
            errorFields = errorFields && errorFields != '' ? errorFields + ', Street' : 'Street';
            isError = true;
        }
        if (!this.address.City) {
            errorFields = errorFields && errorFields != '' ? errorFields + ', City' : 'City';
            isError = true;
        }
        if (!this.address.State) {
            errorFields = errorFields && errorFields != '' ? errorFields + ', State' : 'State';
            isError = true;
        }
        if (!this.address.Country) {
            errorFields = errorFields && errorFields != '' ? errorFields + ', Country' : 'Country';
            isError = true;
        }

        if (isError == false) {
            this.isLoading = true;
            await saveShipmentRequest({
                soId: this.recId,
                accId: this.accountValue,
                address: this.address
            }).then(result => {
                const evt = new ShowToastEvent({
                    title: 'Shipment Request created successful',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                window.open('/' + result, '_self');
                this.isLoading = false;
            }).catch(error => {
                console.error('error>>>', error);
                this.isLoading = false;
            })
        } else {
            const evt = new ShowToastEvent({
                title: 'Please fill required fields: ' + errorFields,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        }
    }
}