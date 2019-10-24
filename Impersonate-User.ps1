$source = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.IO;

namespace Win32Tools
{

    public class Win32
    {

        #region "CONTS"
        const UInt32 INFINITE = 0xFFFFFFFF;
        const UInt32 WAIT_FAILED = 0xFFFFFFFF;
        #endregion


        #region "ENUMS"
        [Flags]
        public enum LogonType

        {

            LOGON32_LOGON_INTERACTIVE = 2,
            LOGON32_LOGON_NETWORK = 3,
            LOGON32_LOGON_BATCH = 4,
            LOGON32_LOGON_SERVICE = 5,
            LOGON32_LOGON_UNLOCK = 7,
            LOGON32_LOGON_NETWORK_CLEARTEXT = 8,
            LOGON32_LOGON_NEW_CREDENTIALS = 9

        }

        [Flags]
        public enum LogonProvider

        {

            LOGON32_PROVIDER_DEFAULT = 0,
            LOGON32_PROVIDER_WINNT35,
            LOGON32_PROVIDER_WINNT40,
            LOGON32_PROVIDER_WINNT50

        }

        #endregion


        #region "STRUCTS"
        [StructLayout(LayoutKind.Sequential)]
        public struct STARTUPINFO
        {

            public Int32 cb;
            public String lpReserved;
            public String lpDesktop;
            public String lpTitle;
            public Int32 dwX;
            public Int32 dwY;
            public Int32 dwXSize;
            public Int32 dwYSize;
            public Int32 dwXCountChars;
            public Int32 dwYCountChars;
            public Int32 dwFillAttribute;
            public Int32 dwFlags;
            public Int16 wShowWindow;
            public Int16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;

        }

        [StructLayout(LayoutKind.Sequential)]
        public struct PROCESS_INFORMATION
        {

            public IntPtr hProcess;
            public IntPtr hThread;
            public Int32 dwProcessId;
            public Int32 dwThreadId;
        }

        #endregion


        #region "FUNCTIONS (P/INVOKE)"

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern Boolean CreateProcessWithLogonW
        (

            String lpszUsername,
            String lpszDomain,
            String lpszPassword,
            Int32 dwLogonFlags,
            String applicationName,
            String commandLine,
            Int32 creationFlags,
            IntPtr environment,
            String currentDirectory,
            ref STARTUPINFO sui,
            out PROCESS_INFORMATION processInfo
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern UInt32 WaitForSingleObject
        (

            IntPtr hHandle,
            UInt32 dwMilliseconds
        );


        [DllImport("kernel32", SetLastError = true)]
        public static extern Boolean CloseHandle(IntPtr handle);

        #endregion

        #region "FUNCTIONS"
        public static void StartProcessAs(string strCommand, string strDomain, string strName, string strPassword)
        {

            // Variables
            PROCESS_INFORMATION processInfo = new PROCESS_INFORMATION();
            STARTUPINFO startInfo = new STARTUPINFO();
            bool bResult = false;
            UInt32 uiResultWait = WAIT_FAILED;
            try
            {
                // Create process
                startInfo.cb = Marshal.SizeOf(startInfo);
                bResult = CreateProcessWithLogonW(
                    strName,
                    strDomain,
                    strPassword,
                    0,
                    null,
                    strCommand,
                    0,
                    IntPtr.Zero,
                    null,
                    ref startInfo,
                    out processInfo
                );

                if (!bResult) { throw new Exception("CreateProcessWithLogonW error #" + Marshal.GetLastWin32Error().ToString()); }
                // Wait for process to end

                uiResultWait = WaitForSingleObject(processInfo.hProcess, INFINITE);
                if (uiResultWait == WAIT_FAILED) { throw new Exception("WaitForSingleObject error #" + Marshal.GetLastWin32Error()); }
            }

            finally

            {

                // Close all handles
                CloseHandle(processInfo.hProcess);
                CloseHandle(processInfo.hThread);
            }

        }

        #endregion

    }

}
"@

Add-Type $source -Language CSharp
[Win32Tools.Win32]::StartProcessAs("C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe", "desktop-e1b4bo3", "test", "P@55w0rd1")
