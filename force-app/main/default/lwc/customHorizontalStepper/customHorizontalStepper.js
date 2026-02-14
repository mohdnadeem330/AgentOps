import { api, LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';

export default class CustomHorizontalStepper extends LightningElement {



    previousStepIcon = resourcesPath + "/ALDARResources/svg/CompleteStepIcon.svg";

    @api array;

    @api canProceed = false;

    connectedCallback() { }

    handleSelection(event) {
        this.dispatchEvent(new CustomEvent('getselectedstep', {detail: {childcomponentevent:event}}));
    }


}