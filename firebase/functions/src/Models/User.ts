export class User {
    profile: UserProfile;
    data: UserData;

    constructor() {
        this.profile = new UserProfile("", "", "");
        this.data = new UserData();
    }

    // constructor(name: string, email: string, profileImageUrl: string) {
    //     this.profile = new UserProfile(name, email, profileImageUrl);
    //     this.data = new UserData();
    // }
}

class UserProfile {
    displayName: string;
    email: string;
    imageProfileUrl: string;

    constructor(displayName: string, email: string, profileImageUrl: string) {
        this.displayName = displayName;
        this.email = email;
        this.imageProfileUrl = profileImageUrl;
    }
}

class UserData {
    signIns: number;
    appVersion: string;

    constructor() {
        this.signIns = 0;
        this.appVersion = "";
    }
}
