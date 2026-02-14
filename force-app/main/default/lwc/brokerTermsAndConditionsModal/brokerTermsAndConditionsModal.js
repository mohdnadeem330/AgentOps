import { LightningElement, track } from 'lwc';
import BrokerTermsAndConditions from '@salesforce/label/c.BrokerTermsAndConditions';

export default class BrokerTermsAndConditionsModal extends LightningElement {

    showFrame = true; 
    url;

    handleClick(event){
        let eventType = event.target.name;
        eventType = (eventType === 'accept' || eventType === 'refuse') ? eventType : 'close';
       
        this.dispatchEvent(new CustomEvent('termsconditions', {detail:{ type : eventType }}));

    }

    connectedCallback(){
        this.url = BrokerTermsAndConditions;
    }

    renderedCallback()
    {
        //const iframe = this.template.querySelectorAll('[data-item="iframeItem"]');
        //const iframe = this.template.querySelector('#x_termsiframe');
        //console.log('logger----renderedCallback');
        //console.log(iframe.contentWindow);
        //console.log(JSON.stringify(iframe.contentWindow.document.getElementsByClassName("downloadbutton")));

    }

}