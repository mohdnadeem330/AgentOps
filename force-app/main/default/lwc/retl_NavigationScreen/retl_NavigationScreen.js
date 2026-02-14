import { LightningElement, track, wire, api } from 'lwc';
import HomeImages from "@salesforce/resourceUrl/HomeImages";
import getCurrentUser from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUser';
export default class Retl_NavigationScreen extends LightningElement {
    Logo = HomeImages + '/Home-Images/DM_logo_login.png';
    profileAvatarUrl = '/resources/profile-avatar.png';
    showServiceRequest = false;
    showProfile = false;
    @track user = {};
    vertical;
    @api hideServiceRequestScreen = false;
    alreadyVisited = false;
    connectedCallback() {
        console.log('hideServiceRequestScreen', this.hideServiceRequestScreen)
        this.alreadyVisited = sessionStorage.getItem('navRequestsVisited');
        console.log('alreadyVisited', this.alreadyVisited);

        if (!this.alreadyVisited) {
            this.navigateToServiceRequest();
        }

    }
    @wire(getCurrentUser)
    wiredUser({ data, error }) {
        if (data) {
            console.log('data', JSON.stringify(data))
            this.user = data;
            this.vertical = data.Contact?.Account?.CustomerVertical__c;
            console.log('this.vertical', this.vertical);
        } else if (error) {

            this.user = undefined;
        }
    }
    get userInitials() {
        if (this.user) {
            return (
                (this.user.Contact?.FirstName ? this.user.Contact.FirstName.charAt(0) : '') +
                (this.user.Contact?.LastName ? this.user.Contact.LastName.charAt(0) : '')
            ).toUpperCase();
        }
        return '';
    }
    navigateToServiceRequest() {
        //this.showServiceRequest = true;
        this.showProfile = false;
        this.hideServiceRequestScreen = true;
        sessionStorage.setItem('navRequestsVisited', 'true');
        window.open('/business/retail', "_self");
    }

    navigateToProfile() {
        this.showServiceRequest = false;
        //this.showProfile = true;
        window.open('/business/profile', "_self");
    }
}