//
//  main.cpp
//  MeerkatWifiScannerMacOS
//
//  Created by Németh László Harri on 2018. 05. 15..
//
// MIT License
//
// Copyright (c) 2018 László Harri Németh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <vector>
#include <iostream>

#include <ncurses.h>
#include <menu.h>

#import <CoreWLAN/CoreWLAN.h>

using namespace std;

volatile sig_atomic_t done = 0;

struct AccessPoint {
    string ssid;
    string bssid;
    int rssi;
    long wlanChannel;
};

void term(int signum);
vector<AccessPoint> ScanAir();
WINDOW *create_newwin(int height, int width, int starty, int startx);
void destroy_win(WINDOW *local_win);

int main(int argc, const char * argv[]) {
    
    // handle unix signals SIGINT and SIGTERM
    struct sigaction action;
    memset(&action, 0, sizeof(struct sigaction));
    action.sa_handler = term;
    sigaction(SIGINT, &action, NULL);
    sigaction(SIGTERM, &action, NULL);

    // variables for ncurses - window and dimensions
    WINDOW *my_win = nullptr;
    int startx, starty, width, height;
    
    // variable for AP list
    vector<AccessPoint> aps;
    
    // minimal and maximal signal strengths for visualization
    signed int mindBmValue = 0, maxdBmValue = -1000;
    
    // init ncurses
    initscr();
    
    // Line buffering disabled
    cbreak();
    
    // variables for calculating window size
    height = LINES - 5;
    width = COLS - 10;
    starty = (LINES - height) / 2;    /* Calculating for a center placement */
    startx = (COLS - width) / 2;    /* of the window        */
    printw("Press CTRL+C to exit");
    refresh();
    
    while (!done) {
        
        // refresh every 1 second
        sleep(1);

        // get list of AP's
        aps = ScanAir();

        // get min and max RSSI
        for (auto it = aps.begin(); it != aps.end(); it++) {
            if ((*it).rssi < mindBmValue) mindBmValue = (*it).rssi;
            if ((*it).rssi > maxdBmValue) maxdBmValue = (*it).rssi;
        }

        // destroy old window and create new one
        if (my_win) destroy_win(my_win);
        my_win = create_newwin(height, width, starty, startx);
        
        // build window data
        int rowIndex = 1;
        for (auto it = aps.begin(); it != aps.end(); it++) {
            string ssid = (*it).ssid;
            int dBmValue = (*it).rssi;
            int signalStrengthsBarLength = (int)( ((double)(dBmValue - mindBmValue) / (double)(maxdBmValue - mindBmValue)) * (double)(width - 2 - 30) );

            if (ssid.length() > 20) ssid = ssid.substr(0,17) + "...";
            mvwprintw(my_win, rowIndex, 1, ssid.c_str());
            mvwprintw(my_win, rowIndex, 22, to_string(dBmValue).c_str());
            mvwprintw(my_win, rowIndex, 26, to_string((*it).wlanChannel).c_str());
            for (int n = 1; n < signalStrengthsBarLength; n++) mvwprintw(my_win, rowIndex, 29+n, ">");

            wrefresh(my_win);
            rowIndex++;
            if (rowIndex > height - 2) break;
        }

    }
    
    // End curses mode
    endwin();
    
    cout << "Normal exit" << endl;
    return 0;
}

// terminate
void term(int signum) {
    done = 1;
}

/****************************
 * wifi scanning helper methods
 *****************************/

// scan for wifi access points
vector<AccessPoint> ScanAir() {
    CWWiFiClient* wfc = CWWiFiClient.sharedWiFiClient;
    CWInterface* interface = wfc.interface; // get default interface
    
    NSError* error = nil;
    NSArray* scanResult = [[interface scanForNetworksWithSSID:nil error:&error] allObjects];
    
    if (error) {
        NSLog(@"%@ (%ld)", [error localizedDescription], [error code]);
    }
    
    vector<AccessPoint> result;
    for (CWNetwork* network in scanResult) {
        AccessPoint ap;
        ap.ssid  = string([[network ssid] UTF8String]);
        ap.bssid = string([[network bssid] UTF8String]);
        ap.rssi = (int)[network rssiValue];
        ap.wlanChannel = (long)[[network wlanChannel] channelNumber];
        result.push_back(ap);
    }
    
    return result;
}


/****************************
* ncurses helper methods
*****************************/

// create window
WINDOW *create_newwin(int height, int width, int starty, int startx) {
    WINDOW *local_win;
    local_win = newwin(height, width, starty, startx);
    box(local_win, 0 , 0);        /* 0, 0 gives default characters
                                   * for the vertical and horizontal
                                   * lines            */
    wrefresh(local_win);        /* Show that box         */
    return local_win;
}

// destroy window
void destroy_win(WINDOW *local_win) {
    /* box(local_win, ' ', ' '); : This won't produce the desired
     * result of erasing the window. It will leave it's four corners
     * and so an ugly remnant of window.
     */
    wborder(local_win, ' ', ' ', ' ',' ',' ',' ',' ',' ');
    /* The parameters taken are
     * 1. win: the window on which to operate
     * 2. ls: character to be used for the left side of the window
     * 3. rs: character to be used for the right side of the window
     * 4. ts: character to be used for the top side of the window
     * 5. bs: character to be used for the bottom side of the window
     * 6. tl: character to be used for the top left corner of the window
     * 7. tr: character to be used for the top right corner of the window
     * 8. bl: character to be used for the bottom left corner of the window
     * 9. br: character to be used for the bottom right corner of the window
     */
    wrefresh(local_win);
    delwin(local_win);
}

