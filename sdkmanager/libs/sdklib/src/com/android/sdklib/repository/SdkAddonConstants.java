/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Eclipse Public License, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.eclipse.org/org/documents/epl-v10.php
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.sdklib.repository;


import java.io.InputStream;

/**
 * Public constants for the sdk-addon XML Schema.
 */
public class SdkAddonConstants extends RepoConstants {

    /** The URL where to find the official addons list fle. */
    public static final String URL_ADDON_LIST =
        "https://dl-ssl.google.com/android/repository/addons_list.txt";    //$NON-NLS-1$

    public static final String URL_DEFAULT_XML_FILE = "addon.xml";         //$NON-NLS-1$

    /** The base of our sdk-addon XML namespace. */
    private static final String NS_BASE =
        "http://schemas.android.com/sdk/android/addon/";                   //$NON-NLS-1$

    /**
     * The pattern of our sdk-addon XML namespace.
     * Matcher's group(1) is the schema version (integer).
     */
    public static final String NS_PATTERN = NS_BASE + "([1-9][0-9]*)";     //$NON-NLS-1$

    /** The latest version of the sdk-addon XML Schema.
     *  Valid version numbers are between 1 and this number, included. */
    public static final int NS_LATEST_VERSION = 1;

    /** The XML namespace of the latest sdk-addon XML. */
    public static final String NS_URI = getSchemaUri(NS_LATEST_VERSION);

    /** The root sdk-addon element */
    public static final String NODE_SDK_ADDON       = "sdk-addon";         //$NON-NLS-1$

    /** An add-on package. */
    public static final String NODE_ADD_ON          = "add-on";            //$NON-NLS-1$

    /**
     * List of possible nodes in a repository XML. Used to populate options automatically
     * in the no-GUI mode.
     */
    public static final String[] NODES = {
        NODE_ADD_ON,
        NODE_EXTRA
    };

    /**
     * Returns a stream to the requested sdk-addon XML Schema.
     *
     * @param version Between 1 and {@link #NS_LATEST_VERSION}, included.
     * @return An {@link InputStream} object for the local XSD file or
     *         null if there is no schema for the requested version.
     */
    public static InputStream getXsdStream(int version) {
        String filename = String.format("sdk-addon-%d.xsd", version);      //$NON-NLS-1$
        return SdkAddonConstants.class.getResourceAsStream(filename);
    }

    /**
     * Returns the URI of the sdk-addon schema for the given version number.
     * @param version Between 1 and {@link #NS_LATEST_VERSION} included.
     */
    public static String getSchemaUri(int version) {
        return String.format(NS_BASE + "%d", version);           //$NON-NLS-1$
    }
}
