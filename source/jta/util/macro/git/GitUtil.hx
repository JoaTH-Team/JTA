package jta.util.macro.git;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.Process;
#end

/**
 * Utility class for Git operations.
 */
class GitUtil
{
	/**
	 * Retrieves the short commit hash of the current Git HEAD.
	 * @return The short commit hash as a macro expression.
	 */
	public static macro function getCommitHash():Expr
	{
		#if !display
		try
		{
			final proc:Process = new Process('git', ['rev-parse', '--short', 'HEAD']);
			proc.exitCode(true);
			return macro $v{proc.stdout.readLine()};
		}
		catch (e:Dynamic) {}
		#end

		return macro $v{'---'};
	}

	/**
	 * Retrieves the commit number (count) of the current Git HEAD.
	 * @return The commit number as a macro expression.
	 */
	public static macro function getCommitNumber():Expr
	{
		#if !display
		try
		{
			final proc:Process = new Process('git', ['rev-list', '--count', 'HEAD']);
			proc.exitCode(true);
			return macro $v{Std.parseInt(proc.stdout.readLine())};
		}
		catch (e:Dynamic) {}
		#end

		return macro $v{0};
	}

	/**
	 * Retrieves the name of the current Git branch.
	 * @return The current branch name as a macro expression.
	 */
	public static macro function getCurrentBranch():Expr
	{
		#if !display
		try
		{
			final proc:Process = new Process('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
			proc.exitCode(true);
			return macro $v{proc.stdout.readLine()};
		}
		catch (e:Dynamic) {}
		#end

		return macro $v{'unknown'};
	}

	/**
	 * Retrieves the remote URL of the current Git repository.
	 * @return The remote URL as a macro expression.
	 */
	public static macro function getRemoteUrl():Expr
	{
		#if !display
		try
		{
			final proc:Process = new Process('git', ['remote', 'get-url', 'origin']);
			proc.exitCode(true);
			return macro $v{proc.stdout.readLine()};
		}
		catch (e:Dynamic) {}
		#end

		return macro $v{'unknown'};
	}

	/**
	 * Checks if the current Git repository has uncommitted changes.
	 * @return true if there are uncommitted changes, false otherwise.
	 */
	public static macro function isRepositoryDirty():Expr
	{
		#if !display
		try
		{
			final proc:Process = new Process('git', ['status', '--porcelain']);
			proc.exitCode(true);
			return macro $v{cast(proc.stdout.readAll(), String).trim().length > 0};
		}
		catch (e:Dynamic) {}
		#end

		return macro $v{false};
	}
}
