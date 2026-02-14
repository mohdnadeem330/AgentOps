import { LightningElement, api } from 'lwc';

export default class GenerateSelectedDocuments extends LightningElement {
    @api recordIds; //Dummy Attribute for now
    @api documentsList = [];
    connectedCallback() {
        sessionStorage['documentsList'] = this.documentsList;
    }
}