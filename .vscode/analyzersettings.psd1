@{
    CustomRulePath      = @(
        '.\output\RequiredModules\DscResource.AnalyzerRules'
        '.\output\RequiredModules\Indented.ScriptAnalyzerRules'
    )
    IncludeDefaultRules = $true
    IncludeRules        = @(
        # DSC Resource Kit style guideline rules.
        'PSAvoidDefaultValueForMandatoryParameter'
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidInvokingEmptyMembers'
        'PSAvoidNullOrEmptyHelpMessageAttribute'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingComputerNameHardcoded'
        'PSAvoidUsingDeprecatedManifestFields'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidShouldContinueWithoutForce'
        'PSAvoidUsingWMICmdlet'
        'PSAvoidUsingWriteHost'
        'PSDSCReturnCorrectTypesForDSCFunctions'
        'PSDSCStandardDSCFunctionsInResource'
        'PSDSCUseIdenticalMandatoryParametersForDSC'
        'PSDSCUseIdenticalParametersForDSC'
        'PSMisleadingBacktick'
        'PSMissingModuleManifestField'
        'PSPossibleIncorrectComparisonWithNull'
        'PSProvideCommentHelp'
        'PSReservedCmdletChar'
        'PSReservedParams'
        'PSUseApprovedVerbs'
        'PSUseCmdletCorrectly'
        'PSUseOutputTypeCorrectly'
        'PSAvoidGlobalVars'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingUsernameAndPasswordParams'
        'PSDSCUseVerboseMessageInDSCResource'
        'PSShouldProcess'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUsePSCredentialType'

        # Additional rules from the module ScriptAnalyzer
        'PSUseConsistentWhitespace'
        'UseCorrectCasing'
        'PSPlaceOpenBrace'
        'PSPlaceCloseBrace'
        'AlignAssignmentStatement'
        'AvoidUsingDoubleQuotesForConstantString'
        'UseShouldProcessForStateChangingFunctions'

        # Rules from the modules DscResource.AnalyzerRules
        'Measure-*'

        # Rules from the module Indented.ScriptAnalyzerRules
        'AvoidCreatingObjectsFromAnEmptyString'
        'AvoidDashCharacters'
        'AvoidEmptyNamedBlocks'
        'AvoidFilter'
        'AvoidHelpMessage'
        'AvoidNestedFunctions'
        'AvoidNewObjectToCreatePSObject'
        'AvoidParameterAttributeDefaultValues'
        'AvoidProcessWithoutPipeline'
        'AvoidSmartQuotes'
        'AvoidThrowOutsideOfTry'
        'AvoidWriteErrorStop'
        'AvoidWriteOutput'
        'UseSyntacticallyCorrectExamples'
    )

}
