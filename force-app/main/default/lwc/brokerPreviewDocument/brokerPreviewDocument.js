import { LightningElement,api } from 'lwc';

export default class BrokerPreviewDocument extends LightningElement {
    @api url;
    @api titleForTheDocument;

    handleClick(event){
        // alert('inn');
        // this.dispatchEvent(new CustomEvent('closepreview', {detail:{ type : false }}));
        this.dispatchEvent(new CustomEvent('closepreview',{detail:{isOpen:false}}));
    }
}